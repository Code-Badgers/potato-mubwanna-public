package com.gamjamubwatna.notice.api;

import com.gamjamubwatna.auth.api.AuthApiResponse;
import com.gamjamubwatna.notice.application.AdminNoticeService;
import com.gamjamubwatna.notice.application.NoticeNotFoundException;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/admin/notices")
public class AdminNoticeController {

    private final AdminNoticeService adminNoticeService;

    public AdminNoticeController(AdminNoticeService adminNoticeService) {
        this.adminNoticeService = adminNoticeService;
    }

    // 관리 화면에서 초안과 숨김 공지를 포함한 전체 운영 목록을 조회한다.
    @GetMapping
    public ResponseEntity<AuthApiResponse<AdminNoticeListResponse>> getNotices() {
        return ResponseEntity.ok(AuthApiResponse.success(adminNoticeService.getNotices()));
    }

    // 운영 공지를 초안 또는 즉시 게시 상태로 생성한다.
    @PostMapping
    public ResponseEntity<AuthApiResponse<AdminNoticeResponse>> create(
        @Valid @RequestBody AdminNoticeCreateRequest request
    ) {
        AdminNoticeResponse response = adminNoticeService.create(
            request.title(),
            request.content(),
            request.published()
        );
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(AuthApiResponse.success(response));
    }

    // 게시 상태와 발행 시각을 유지하면서 공지 제목과 내용을 전체 교체한다.
    @PutMapping("/{noticeId}")
    public ResponseEntity<AuthApiResponse<AdminNoticeResponse>> update(
        @PathVariable Long noticeId,
        @Valid @RequestBody AdminNoticeUpdateRequest request
    ) {
        try {
            return ResponseEntity.ok(AuthApiResponse.success(adminNoticeService.update(
                noticeId,
                request.title(),
                request.content()
            )));
        } catch (NoticeNotFoundException exception) {
            return notFound();
        }
    }

    // 숨김과 게시를 전환하며 새로 게시할 때만 발행 시각을 현재 시각으로 갱신한다.
    @PatchMapping("/{noticeId}/publication")
    public ResponseEntity<AuthApiResponse<AdminNoticeResponse>> changePublication(
        @PathVariable Long noticeId,
        @Valid @RequestBody AdminNoticePublicationRequest request
    ) {
        try {
            return ResponseEntity.ok(AuthApiResponse.success(
                adminNoticeService.changePublication(noticeId, request.published())
            ));
        } catch (NoticeNotFoundException exception) {
            return notFound();
        }
    }

    private ResponseEntity<AuthApiResponse<AdminNoticeResponse>> notFound() {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(AuthApiResponse.failure("공지를 찾을 수 없습니다."));
    }
}
