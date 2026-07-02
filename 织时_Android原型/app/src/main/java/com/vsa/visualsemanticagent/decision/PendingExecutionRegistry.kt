package com.vsa.visualsemanticagent.decision

data class PendingExecutionEntry(
    val intent: ExecutableIntent,
    val suggestion: ExecutionSuggestion,
    val sourceLabel: String = "",
    val sourcePreview: String = ""
)

data class PendingExecutionSnapshot(
    val entries: List<PendingExecutionEntry> = emptyList(),
    val activeKey: String? = null
) {
    val activeEntry: PendingExecutionEntry?
        get() {
            val matched = entries.firstOrNull { it.intent.stabilityKey == activeKey }
            return matched ?: entries.firstOrNull()
        }
}

object PendingExecutionRegistry {

    fun upsert(
        snapshot: PendingExecutionSnapshot,
        entry: PendingExecutionEntry,
        activate: Boolean = true
    ): PendingExecutionSnapshot {
        val mergedEntries = listOf(entry) + snapshot.entries.filterNot {
            it.intent.stabilityKey == entry.intent.stabilityKey
        }
        return snapshot.copy(
            entries = mergedEntries,
            activeKey = if (activate) entry.intent.stabilityKey else snapshot.activeEntry?.intent?.stabilityKey
        ).normalize()
    }

    fun remove(
        snapshot: PendingExecutionSnapshot,
        stabilityKey: String
    ): PendingExecutionSnapshot {
        val remaining = snapshot.entries.filterNot { it.intent.stabilityKey == stabilityKey }
        val nextActiveKey = if (snapshot.activeKey == stabilityKey) {
            remaining.firstOrNull()?.intent?.stabilityKey
        } else {
            snapshot.activeKey
        }
        return snapshot.copy(entries = remaining, activeKey = nextActiveKey).normalize()
    }

    fun replace(
        snapshot: PendingExecutionSnapshot,
        originalKey: String,
        updatedEntry: PendingExecutionEntry,
        activate: Boolean = true
    ): PendingExecutionSnapshot {
        val withoutOriginal = snapshot.entries.filterNot { it.intent.stabilityKey == originalKey }
        val mergedEntries = listOf(updatedEntry) + withoutOriginal.filterNot {
            it.intent.stabilityKey == updatedEntry.intent.stabilityKey
        }
        return snapshot.copy(
            entries = mergedEntries,
            activeKey = if (activate) updatedEntry.intent.stabilityKey else snapshot.activeEntry?.intent?.stabilityKey
        ).normalize()
    }

    private fun PendingExecutionSnapshot.normalize(): PendingExecutionSnapshot {
        val normalizedActiveKey = activeEntry?.intent?.stabilityKey
        return copy(activeKey = normalizedActiveKey)
    }
}
