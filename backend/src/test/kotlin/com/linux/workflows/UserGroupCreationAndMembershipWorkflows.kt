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
    fun `A User Can Create a Group`() {
        val user = adminClient.createUser()
        val group = adminClient.createGroup(user)
        assertThat(group).isNotNull.satisfies({
            assertThat(it.createdBy).isEqualTo(user.id)
            assertThat(it.active).isTrue
        })
    }
}