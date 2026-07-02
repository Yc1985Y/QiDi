package com.vsa.visualsemanticagent

import androidx.test.ext.junit.runners.AndroidJUnit4
import com.vsa.visualsemanticagent.input.NoticeSourceType
import com.vsa.visualsemanticagent.input.TextInputClearPolicy
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class TextInputClearPolicyTests {

    @Test
    fun successfulManualAndClipboardParsesShouldClearInput() {
        assertTrue(TextInputClearPolicy.shouldClearAfterSuccessfulParse(NoticeSourceType.MANUAL_TEXT))
        assertTrue(TextInputClearPolicy.shouldClearAfterSuccessfulParse(NoticeSourceType.CLIPBOARD))
        assertTrue(TextInputClearPolicy.shouldClearAfterSuccessfulParse(NoticeSourceType.VOICE))
        assertTrue(TextInputClearPolicy.shouldClearAfterSuccessfulParse(NoticeSourceType.SHARE_TEXT))
    }

    @Test
    fun imageParsesAndFailuresShouldKeepInputUntilUserReacts() {
        assertFalse(TextInputClearPolicy.shouldClearAfterSuccessfulParse(NoticeSourceType.CAMERA))
        assertFalse(TextInputClearPolicy.shouldClearAfterSuccessfulParse(NoticeSourceType.SHARE_IMAGE))
        assertFalse(TextInputClearPolicy.shouldClearAfterSuccessfulParse(null))
    }
}
