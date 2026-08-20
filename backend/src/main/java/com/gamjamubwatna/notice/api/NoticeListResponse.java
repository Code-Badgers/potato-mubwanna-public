package com.gamjamubwatna.notice.api;

import java.util.List;

public record NoticeListResponse(
    List<NoticeResponse> items
) {
}
