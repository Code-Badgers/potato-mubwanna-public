package com.gamjamubwatna.potato.api;

import com.gamjamubwatna.potato.domain.PotatoInteractionAction;

public record PotatoInteractionRequest(
    PotatoInteractionAction action
) {
}
