package com.gamjamubwatna.auth.infrastructure;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import org.springframework.http.HttpHeaders;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtTokenProvider jwtTokenProvider;

    public JwtAuthenticationFilter(JwtTokenProvider jwtTokenProvider) {
        this.jwtTokenProvider = jwtTokenProvider;
    }

    @Override
    protected void doFilterInternal(
        HttpServletRequest request,
        HttpServletResponse response,
        FilterChain filterChain
    ) throws ServletException, IOException {
        String authorization = request.getHeader(HttpHeaders.AUTHORIZATION);
        if (authorization != null && authorization.startsWith("Bearer ")) {
            authenticate(authorization.substring("Bearer ".length()));
        }

        filterChain.doFilter(request, response);
    }

    private void authenticate(String token) {
        try {
            JwtTokenProvider.JwtClaims claims = jwtTokenProvider.parse(token);
            if (!"access".equals(claims.tokenType())) {
                return;
            }

            UsernamePasswordAuthenticationToken authentication =
                new UsernamePasswordAuthenticationToken(
                    claims.subject(),
                    null,
                    List.of(new SimpleGrantedAuthority("ROLE_USER"))
                );
            SecurityContextHolder.getContext().setAuthentication(authentication);
        } catch (IllegalArgumentException ignored) {
            SecurityContextHolder.clearContext();
        }
    }
}
