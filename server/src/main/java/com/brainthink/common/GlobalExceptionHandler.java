package com.brainthink.common;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.client.RestClientResponseException;

@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ApiResult<Void>> handleBusiness(BusinessException ex) {
        log.warn("BusinessException: code={}, msg={}", ex.getCode(), ex.getMessage());
        return ResponseEntity.ok(ApiResult.error(ex.getCode(), ex.getMessage()));
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ApiResult<Void>> handleAccessDenied(AccessDeniedException ex) {
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
                .body(ApiResult.error(40300, ex.getMessage()));
    }

    @ExceptionHandler(RestClientResponseException.class)
    public ResponseEntity<ApiResult<Void>> handleUpstream(RestClientResponseException ex) {
        log.error("Upstream error {} body={}", ex.getStatusCode(), ex.getResponseBodyAsString());
        return ResponseEntity.ok(ApiResult.error(50200,
                "上游平台调用失败：" + ex.getStatusCode().value()));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResult<Void>> handleAny(Exception ex) {
        log.error("Unexpected error", ex);
        return ResponseEntity.ok(ApiResult.error(50000,
                ex.getMessage() == null ? "服务异常" : ex.getMessage()));
    }
}
