package com.gamjamubwatna.auth.infrastructure;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class AdminUserIdPolicyTest {

    @Test
    void allowsConfiguredUserIdsAfterTrimmingWhitespace() {
        AdminUserIdPolicy policy = new AdminUserIdPolicy("42, 99,42");

        assertThat(policy.isAdmin("42")).isTrue();
        assertThat(policy.isAdmin("99")).isTrue();
        assertThat(policy.isAdmin("1")).isFalse();
    }

    @Test
    void deniesEveryUserWhenConfigurationIsBlank() {
        AdminUserIdPolicy policy = new AdminUserIdPolicy("  ");

        assertThat(policy.isAdmin("42")).isFalse();
        assertThat(policy.isAdmin(null)).isFalse();
    }
}
