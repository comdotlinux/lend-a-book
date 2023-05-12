package com.linux.clients

import kotlin.random.Random

class UserClient(val user: User) {
    private val adminClient = AdminClient()


    fun createGroup(name: String = "TestGroup${Random.nextInt()}"): Group = adminClient.adminClientBuilder().asUser(user.id).gql(
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
    """.trimIndent(), mapOf("name" to name), mapper = { Group.fromJson(it.asJsonObject()) }
    )

    fun getMemberships(groupId: Int): List<Membership> = adminClient.adminClientBuilder().asUser(user.id).gql(
        """
        query GetMemberships(${'$'}groupId: Int = 10) {
          lend_a_book_membership(where: {group_id: {_eq: ${'$'}groupId}}) {
            user_id
            updated_at
            id
            created_at
            group_id
            admin
          }
        }
    """.trimIndent(), mapOf("groupId" to groupId), responseDataKey = "lend_a_book_membership"
    ) {
        it.asJsonArray().map { memberships -> Membership.fromJson(memberships.asJsonObject()) }.toList()
    }

}