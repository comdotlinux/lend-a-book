package com.linux.jwt

import io.smallrye.jwt.build.Jwt
import org.assertj.core.api.Assertions.assertThat
import org.eclipse.microprofile.jwt.Claim
import org.eclipse.microprofile.jwt.Claims
import org.junit.jupiter.api.Test
import java.time.Instant
import java.util.Base64
import javax.crypto.SecretKey


/**
 * Way to generate JWT however according to https://hasura.io/docs/latest/auth/authentication/admin-secret-access/
 * we might not need JWT in the tests as we can use Admin Secret in combination of user id to "simulate the user"
 * Nevertheless this is present here if need be.
 */
class GenerateJwt {
    /**
     * Generate JWT token
     */
    fun testJwt(): String {
        return Jwt.issuer("keycloak")
            .issuedAt(Instant.now())
            .subject("user")
            .upn("jdoe@quarkus.io")
            .claim("https://hasura.io/jwt/claims", mapOf(
                "X-Hasura-Default-Role" to "user",
                "X-Hasura-Allowed-Roles" to listOf("user"),
                "X-Hasura-User-Id" to "1",
                "X-Hasura-Email-Id" to "jdoe@quarkus.io"
            ))
            .signWithSecret("tTs9ogeMo03XQA1csK5Foyrq1LStR5crrztMFGvLJF47tuINncX1R58bp6sa9WQ3GGIC3P")
    }

    @Test
    fun checkJwt() {
        assertThat(testJwt()).isNotBlank.satisfies({
            assertThat(it).matches("(^[\\w-]*\\.[\\w-]*\\.[\\w-]*\$)")
        })
    }
}