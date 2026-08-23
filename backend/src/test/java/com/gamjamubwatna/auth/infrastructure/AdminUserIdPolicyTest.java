package com.gamjamubwatna.auth.infrastructure;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class AdminUserIdPolicyTest {

    @Test
    void allowsConfiguredUserIdsAfterTrimmingWhitespace() {
        AdminUserIdPolicy policy = new AdminUserIdPolicy("42, 99,42");

        assertThat(policy.isAdmin("user:42")).isTrue();
        assertThat(policy.isAdmin("user:99")).isTrue();
        assertThat(policy.isAdmin("user:1")).isFalse();
    }

    @Test
    void deniesEveryUserWhenConfigurationIsBlank() {
        AdminUserIdPolicy policy = new AdminUserIdPolicy("  ");

        assertThat(policy.isAdmin("user:42")).isFalse();
        assertThat(policy.isAdmin(null)).isFalse();
    }

    @Test
    void deniesMalformedJwtSubjectsAndConfiguredValues() {
        AdminUserIdPolicy policy = new AdminUserIdPolicy("42,user:99,invalid,0");

        assertThat(policy.isAdmin("42")).isFalse();
        assertThat(policy.isAdmin("admin:42")).isFalse();
        assertThat(policy.isAdmin("user:99")).isFalse();
        assertThat(policy.isAdmin("user:0")).isFalse();
    }
}
