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

    fun DynamicGraphQLClientBuilder.withHeader(key: String, value: String): DynamicGraphQLClientBuilder = this.header(key, value)
    fun DynamicGraphQLClientBuilder.asUser(id: Int): DynamicGraphQLClient = this
        .withHeader("X-Hasura-Role", "user")
        .withHeader("X-Hasura-User-Id", id.toString())
        .build()

    fun <T> DynamicGraphQLClient.gql(query: String, variables: Map<String, Any>, operationName: String?, mapper: (json: JsonObject) -> T): T {
        val operationNameFromGraphQL = extractOperationNameFromGraphQL(query)
        val operationNameValue = operationName ?: operationNameFromGraphQL

        val response = if (variables.isEmpty()) {
            if (operationNameValue.isNotBlank()) {
                executeSync(query, operationNameValue)
            } else {
                executeSync(query)
            }

        } else {
            if (operationNameValue.isNotBlank()) {
                executeSync(query, variables, operationNameValue)
            } else {
                executeSync(query, variables)
            }
        }

        val data = response.data
        if (response.hasError() || !response.hasData()) {
            throw RuntimeException("""$query failed with exception : ${response.errors.joinToString("\n")}""")
        }
        val responseDataJsonKey = data.asJsonObject().keys.first()

        return mapper.invoke(data.getJsonObject(responseDataJsonKey))
    }

    private fun extractOperationNameFromGraphQL(graphQL: String): String {
        val parts = graphQL.split(Regex("\\W"))
        val queryOrMutationIndex = parts.indexOfFirst { it == "query" || it == "mutation" }
        val operationName = parts[queryOrMutationIndex + 1]
        if (operationName.isEmpty()) {
            throw Exception("cannot extract operation name from graphQL. Did you forget to add a name after 'query' or maybe forgot the query keyword? graphQL: $graphQL")
        }
        return operationName
    }

    fun <T> DynamicGraphQLClient.gql(query: String, operationName: String?, mapper: (json: JsonObject) -> T): T = gql(query, mapOf(), operationName, mapper)
    fun <T> DynamicGraphQLClient.gql(query: String, variables: Map<String, Any> = mapOf(), mapper: (json: JsonObject) -> T): T = gql(query, variables, null, mapper)

    fun <T> DynamicGraphQLClient.gql(query: String, mapper: (json: JsonObject) -> T) = gql(query, mapOf(), mapper)

    fun DynamicGraphQLClient.gql(query: String): JsonObject = gql(query) { it }
    fun createUser(name: String = "TestUser${Random.nextInt()}", email: String = "test+${Random.nextInt()}@user.com"): User = adminClientBuilder().build().gql(
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
        User::fromJson
    ).also { users.add(it) }

    fun createGroup(user: User, name: String = "TestGroup${Random.nextInt()}"): Group = adminClientBuilder().asUser(user.id).gql(
        """
        mutation CreateGroup(${'$'}name: String!) {
          insert_lend_a_book_group_one(object: {name: ${'$'}name}) {
              id
              name
              updated_at
              created_by
              created_at
              active
          }
        }
    """.trimIndent(), mapOf("name" to name), Group::fromJson
    )

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