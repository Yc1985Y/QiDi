package com.vsa.visualsemanticagent.utils

object NoticeSegmentExtractor {

    private val strongDateMarker = Regex(
        """(?:周[一二三四五六日天]|星期[一二三四五六日天]|今天|明天|后天|本周[一二三四五六日天]?|下周[一二三四五六日天]?|\d{1,2}月\d{1,2}日|\d{4}[./-]\d{1,2}[./-]\d{1,2})"""
    )

    private val timeMarker = Regex(
        """(?:\d{1,2}:\d{2}|\d{1,2}点(?:\d{1,2}分?)?|\d{1,2}时(?:\d{1,2}分?)?)"""
    )

    fun extractIndependentScheduleSegments(sourceText: String): List<String> {
        val normalized = sourceText
            .replace("\r\n", "\n")
            .replace('\u3000', ' ')
            .trim()
        if (normalized.isBlank()) return emptyList()

        val segments = splitByLines(normalized)
            .flatMap(::splitByInlineDates)
            .map(::normalizeSegment)
            .filter { it.isNotBlank() && containsTimeContext(it) }
            .distinct()

        return segments.takeIf { it.size >= 2 } ?: emptyList()
    }

    private fun splitByLines(sourceText: String): List<String> {
        val rawLines = sourceText
            .split('\n')
            .map { it.trim() }
            .filter { it.isNotBlank() }
        if (rawLines.size <= 1) return listOf(sourceText)

        val grouped = mutableListOf<String>()
        val current = StringBuilder()
        rawLines.forEach { line ->
            val startsNewBlock = containsStrongDate(line) && current.isNotBlank() && containsStrongDate(current.toString())
            if (startsNewBlock) {
                grouped += current.toString().trim()
                current.clear()
            }
            if (current.isNotBlank()) {
                current.append('\n')
            }
            current.append(line)
        }
        if (current.isNotBlank()) {
            grouped += current.toString().trim()
        }
        return grouped.ifEmpty { listOf(sourceText) }
    }

    private fun splitByInlineDates(segment: String): List<String> {
        val matches = strongDateMarker.findAll(segment).toList()
        if (matches.size < 2) return listOf(segment)

        val sharedPrefix = segment.substring(0, matches.first().range.first)
            .trim()
            .trimEnd('：', ':', '-', ' ')

        return matches.mapIndexed { index, match ->
            val start = match.range.first
            val endExclusive = matches.getOrNull(index + 1)?.range?.first ?: segment.length
            val slice = segment.substring(start, endExclusive)
                .trim()
                .trimStart('，', ',', '；', ';', '。', '、')
                .trimEnd('，', ',', '；', ';', '。', '、')
            normalizeSegment(
                when {
                    sharedPrefix.isBlank() -> slice
                    slice.startsWith(sharedPrefix) -> slice
                    else -> "$sharedPrefix $slice"
                }
            )
        }
    }

    private fun normalizeSegment(segment: String): String {
        return segment
            .replace("\n", " ")
            .replace(Regex("""\s+"""), " ")
            .trim()
    }

    private fun containsStrongDate(text: String): Boolean = strongDateMarker.containsMatchIn(text)

    private fun containsTimeContext(text: String): Boolean {
        return containsStrongDate(text) || timeMarker.containsMatchIn(text)
    }
}
