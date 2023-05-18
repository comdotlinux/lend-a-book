package com.linux.workflows

import com.linux.clients.AdminClient
import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test

class UserGroupCreationAndMembershipWorkflows {

    private val adminClient = AdminClient()

    @BeforeEach
    fun tearDown() {
        adminClient.cleanUp()
    }

    @Test
    fun `an admin can create a user`() {
        val user = adminClient.createUser("John Doe", "jo@hn.doe")
        assertThat(user).isNotNull.satisfies({
            assertThat(it.name).isEqualTo("John Doe")
            assertThat(it.email).isEqualTo("jo@hn.doe")
        })
    }


    @Test
    fun `user Can Create a Group and is also then added as an admin in the membership`() {
        val userClient = adminClient.userClient()
        val group = userClient.createGroup()
        assertThat(group).isNotNull.satisfies({
            assertThat(it.createdBy).isEqualTo(userClient.user.id)
            assertThat(it.active).isTrue
        })

        assertThat(userClient.getMemberships(group.id)).hasSize(1).allSatisfy {
            assertThat(it.admin).isTrue
            assertThat(it.userId).isEqualTo(userClient.user.id)
        }
    }

}