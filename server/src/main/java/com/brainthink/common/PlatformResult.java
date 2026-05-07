package com.brainthink.common;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class PlatformResult<T> {
    private int code;
    private String message;
    private T data;

    public boolean isOk() {
        return code == 0;
    }
}
