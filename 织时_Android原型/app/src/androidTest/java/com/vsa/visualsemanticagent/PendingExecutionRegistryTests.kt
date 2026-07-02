package com.vsa.visualsemanticagent

import androidx.test.ext.junit.runners.AndroidJUnit4
import com.vsa.visualsemanticagent.decision.ExecutableIntent
import com.vsa.visualsemanticagent.decision.ExecutablePayload
import com.vsa.visualsemanticagent.decision.ExecutionMode
import com.vsa.visualsemanticagent.decision.ExecutionSuggestion
import com.vsa.visualsemanticagent.decision.IntentRiskLevel
import com.vsa.visualsemanticagent.decision.PendingExecutionEntry
import com.vsa.visualsemanticagent.decision.PendingExecutionRegistry
import com.vsa.visualsemanticagent.decision.PendingExecutionSnapshot
import com.vsa.visualsemanticagent.decision.ValidationResult
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class PendingExecutionRegistryTests {

    @Test
    fun newestPendingItemDoesNotErasePreviousEntry() {
        val first = samplePendingEntry(
            title = "事件A",
            time = "2026-05-26T09:00:00",
            sourceLabel = "相册"
        )
        val second = samplePendingEntry(
            title = "事件B",
            time = "2026-05-26T10:00:00",
            sourceLabel = "相册"
        )

        val snapshot = PendingExecutionRegistry.upsert(
            snapshot = PendingExecutionRegistry.upsert(PendingExecutionSnapshot(), first),
            entry = second
        )

        assertEquals(2, snapshot.entries.size)
        assertEquals("事件B", snapshot.activeEntry?.intent?.title)

        val afterConfirmSecond = PendingExecutionRegistry.remove(snapshot, second.intent.stabilityKey)
        assertEquals(1, afterConfirmSecond.entries.size)
        assertEquals("事件A", afterConfirmSecond.activeEntry?.intent?.title)
    }

    @Test
    fun removingCancelledLatestItemFallsBackToPreviousPendingItem() {
        val first = samplePendingEntry(
            title = "事件A",
            time = "2026-05-26T09:00:00",
            sourceLabel = "相册"
        )
        val third = samplePendingEntry(
            title = "事件C",
            time = "2026-05-26T11:00:00",
            sourceLabel = "相册"
        )

        val snapshot = PendingExecutionRegistry.upsert(
            snapshot = PendingExecutionRegistry.upsert(PendingExecutionSnapshot(), first),
            entry = third
        )

        assertEquals("事件C", snapshot.activeEntry?.intent?.title)

        val afterCancelThird = PendingExecutionRegistry.remove(snapshot, third.intent.stabilityKey)
        assertEquals("事件A", afterCancelThird.activeEntry?.intent?.title)

        val fullyCleared = PendingExecutionRegistry.remove(afterCancelThird, first.intent.stabilityKey)
        assertNull(fullyCleared.activeEntry)
        assertEquals(0, fullyCleared.entries.size)
    }

    @Test
    fun replacingEditedDraftDoesNotKeepOriginalPendingEntry() {
        val original = samplePendingEntry(
            title = "事件A",
            time = "2026-05-26T09:00:00",
            sourceLabel = "相册"
        )
        val edited = samplePendingEntry(
            title = "事件A修改后",
            time = "2026-05-26T10:30:00",
            sourceLabel = "相册"
        )

        val snapshot = PendingExecutionRegistry.upsert(
            snapshot = PendingExecutionSnapshot(),
            entry = original
        )
        val replaced = PendingExecutionRegistry.replace(
            snapshot = snapshot,
            originalKey = original.intent.stabilityKey,
            updatedEntry = edited
        )

        assertEquals(1, replaced.entries.size)
        assertEquals(edited.intent.stabilityKey, replaced.activeEntry?.intent?.stabilityKey)
        assertEquals("事件A修改后", replaced.activeEntry?.intent?.title)
    }
}

private fun samplePendingEntry(
    title: String,
    time: String,
    sourceLabel: String
): PendingExecutionEntry {
    return PendingExecutionEntry(
        intent = ExecutableIntent(
            scene = "campus_schedule_agent",
            action = "create_event",
            payload = ExecutablePayload(
                title = title,
                time = time,
                location = "图书馆"
            ),
            modelConfidence = 0.9,
            fusedConfidence = 0.9,
            fallbackQuery = null,
            requiresConfirmation = true,
            riskLevel = IntentRiskLevel.MEDIUM
        ),
        suggestion = ExecutionSuggestion(
            mode = ExecutionMode.REQUIRE_CONFIRMATION,
            summary = "待确认",
            prompt = "请确认",
            threshold = 0.7,
            validation = ValidationResult(isValid = true, issues = emptyList())
        ),
        sourceLabel = sourceLabel,
        sourcePreview = "$title 原始输入"
    )
}
