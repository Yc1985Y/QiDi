package com.vsa.visualsemanticagent.input

object TextInputClearPolicy {

    fun shouldClearAfterSuccessfulParse(sourceType: NoticeSourceType?): Boolean {
        return sourceType == NoticeSourceType.MANUAL_TEXT ||
            sourceType == NoticeSourceType.CLIPBOARD ||
            sourceType == NoticeSourceType.VOICE ||
            sourceType == NoticeSourceType.SHARE_TEXT
    }
}
