package com.vsa.visualsemanticagent

import androidx.test.ext.junit.runners.AndroidJUnit4
import com.vsa.visualsemanticagent.model.ModelConstants
import com.vsa.visualsemanticagent.model.VLMEventPayload
import com.vsa.visualsemanticagent.model.VLMPayload
import com.vsa.visualsemanticagent.model.VLMResponse
import com.vsa.visualsemanticagent.utils.ResponseInterpreter
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class MultiEventResponseInterpreterTests {

    @Test
    fun expand_splitsMultipleScheduleEventsIntoIndependentResponses() {
        val responses = ResponseInterpreter.expand(
            VLMResponse(
                action = ModelConstants.ACTION_CREATE_EVENT,
                confidence = 0.91,
                payload = VLMPayload(
                    title = "周二例会",
                    time = "2026-05-19T12:00:00",
                    location = "院楼 201"
                ),
                events = listOf(
                    VLMEventPayload(
                        title = "周二例会",
                        time = "2026-05-19T12:00:00",
                        location = "院楼 201",
                        confidence = 0.93
                    ),
                    VLMEventPayload(
                        title = "周三自习",
                        time = "2026-05-20T11:00:00",
                        location = "图书馆三楼",
                        confidence = 0.88
                    )
                )
            )
        )

        assertEquals(2, responses.size)
        assertEquals("周二例会", responses[0].title)
        assertEquals("周三自习", responses[1].title)
        assertEquals("2026-05-20T11:00:00", responses[1].time)
        assertEquals("图书馆三楼", responses[1].location)
    }

    @Test
    fun expand_usesFirstEventWhenPayloadOnlyProvidesEventsArray() {
        val responses = ResponseInterpreter.expand(
            VLMResponse(
                action = ModelConstants.ACTION_CREATE_EVENT,
                confidence = 0.84,
                payload = VLMPayload(),
                events = listOf(
                    VLMEventPayload(
                        title = "算法讨论课",
                        time = "2026-05-22T19:30:00",
                        location = "实验楼 A105",
                        confidence = 0.84
                    )
                )
            )
        )

        assertEquals(1, responses.size)
        assertEquals("算法讨论课", responses.first().title)
        assertEquals("2026-05-22T19:30:00", responses.first().time)
        assertTrue(responses.first().payload?.events.isNullOrEmpty().not())
    }
}
