package com.linux.clients

import io.smallrye.graphql.client.dynamic.api.DynamicGraphQLClient
import io.smallrye.graphql.client.dynamic.api.DynamicGraphQLClientBuilder
import jakarta.json.Json
import jakarta.json.JsonArray
import jakarta.json.JsonObject
import jakarta.json.JsonStructure
import jakarta.json.JsonValue

fun DynamicGraphQLClientBuilder.withHeader(key: String, value: String): DynamicGraphQLClientBuilder = this.header(key, value)
fun DynamicGraphQLClientBuilder.asUser(id: Int): DynamicGraphQLClient = this
    .withHeader("X-Hasura-Role", "user")
    .withHeader("X-Hasura-User-Id", id.toString())
    .build()

fun <T> DynamicGraphQLClient.gql(query: String, variables: Map<String, Any>, operationName: String? = null, responseDataKey: String? = null, mapper: (json: JsonValue) -> T): T {
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

    if (response.hasError() || !response.hasData()) {
        throw RuntimeException("""$query failed with exception : ${response.errors.joinToString("\n")}""")
    }

    val data = response.data
    val responseDataJsonKey = responseDataKey ?: data.keys.first() // TODO get the first query table name
    return mapper.invoke(when(data[responseDataJsonKey]) {
        is JsonObject -> data.getJsonObject(responseDataJsonKey)
        is JsonArray -> data.getJsonArray(responseDataJsonKey)
        else -> data[responseDataJsonKey]!!
    })

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

fun <T> DynamicGraphQLClient.gql(query: String, mapper: (json: JsonValue) -> T) = gql(query, mapOf(), null, null, mapper)
fun <T> DynamicGraphQLClient.gqlToList(query: String, mapper: (json: JsonValue) -> List<T>) = gql(query, mapOf(), null, null, mapper)

fun DynamicGraphQLClient.gql(query: String): JsonValue = gql(query) { it }