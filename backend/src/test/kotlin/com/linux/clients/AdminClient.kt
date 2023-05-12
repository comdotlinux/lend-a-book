package com.linux.clients

import io.smallrye.graphql.client.dynamic.api.DynamicGraphQLClient
import io.smallrye.graphql.client.dynamic.api.DynamicGraphQLClientBuilder
import jakarta.json.JsonObject
import kotlin.random.Random

const val hasuraAdminSecret: String = "OTwAAHn1WyHrfBu3Z2ROQrE5ruTpFt8nQOkxDwIc"
const val graphQlApiUrl = "http://localhost:8080/v1/graphql"

class AdminClient {
    private val users = mutableListOf<User>()

    val adminClientBuilder: () -> DynamicGraphQLClientBuilder = {
        DynamicGraphQLClientBuilder
            .newBuilder()
            .url(graphQlApiUrl)
            .header("X-Hasura-Admin-Secret", hasuraAdminSecret)
    }

    fun createUser(name: String, email: String): User = adminClientBuilder().build().gql(
        """mutation CreateUser(${'$'}name: String!, ${'$'}email: String!) {
              insert_lend_a_book_user_one(object: {name: ${'$'}name, email: ${'$'}email}) {
                id
                active
                created_at
                email
                name
                updated_at
              }
            }""".trimIndent(),
        mapOf("name" to name, "email" to email),
        mapper = { User.fromJson(it.asJsonObject()) }
    ).also { users.add(it) }

    fun userClient(name: String = "TestUser${Random.nextInt()}", email: String = "test+${Random.nextInt()}@user.com"): UserClient = UserClient(createUser(name, email))


/*    fun membership(user: User, group: Group): Membership = adminClientBuilder().asUser(user.id).gql("""
        query GetMembership(${'$'}id: Int!) {
          lend_a_book_membership_by_pk(id: ${'$'}id) {
            admin
            created_at
            group_id
            id
            updated_at
            user_id
          }
        }
    """.trimIndent(), mapOf("id" to id))*/

    private fun deleteAllUsers(): Unit = adminClientBuilder().build().gql(
        """mutation DeleteAll {
              delete_lend_a_book_group(where: {}) {
                 affected_rows
              }
              delete_lend_a_book_user(where: {}) {
                affected_rows
              }
        }""".trimIndent()
    ) {}

    fun cleanUp() {
        deleteAllUsers()
    }

}