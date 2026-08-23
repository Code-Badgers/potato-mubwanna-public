package com.gamjamubwatna.notice.api;

import java.util.List;

public record AdminNoticeListResponse(
    List<AdminNoticeResponse> items
) {
}
