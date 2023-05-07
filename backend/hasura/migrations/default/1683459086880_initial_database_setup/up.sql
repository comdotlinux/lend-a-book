CREATE SCHEMA IF NOT EXISTS lend_a_book;
--
CREATE OR REPLACE FUNCTION "lend_a_book"."set_current_timestamp_updated_at"()
    RETURNS TRIGGER AS
$$
DECLARE
    _new record;
BEGIN
    _new := NEW;
    _new."updated_at" = NOW();
    RETURN _new;
END;
$$ LANGUAGE plpgsql;
--
CREATE TABLE "lend_a_book"."user"
(
    "id"         serial      NOT NULL,
    "name"       text        NOT NULL,
    "active"     boolean     NOT NULL DEFAULT true,
    "email"      text        NOT NULL,
    "created_at" timestamptz NOT NULL DEFAULT now(),
    "updated_at" timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY ("id")
);
COMMENT ON TABLE "lend_a_book"."user" IS E'Holds the people interested in lending or borrowing a book';
--
CREATE TRIGGER "set_lend_a_book_user_updated_at"
    BEFORE UPDATE
    ON "lend_a_book"."user"
    FOR EACH ROW
EXECUTE PROCEDURE "lend_a_book"."set_current_timestamp_updated_at"();
COMMENT ON TRIGGER "set_lend_a_book_user_updated_at" ON "lend_a_book"."user"
    IS 'trigger to set value of column "updated_at" to current timestamp on row update';
--
CREATE TABLE "lend_a_book"."group"
(
    "id"         serial      NOT NULL,
    "name"       text        NOT NULL,
    "active"     boolean     NOT NULL,
    "created_by" Integer     NOT NULL,
    "created_at" timestamptz NOT NULL DEFAULT now(),
    "updated_at" timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY ("id"),
    UNIQUE ("name"),
    FOREIGN KEY ("created_by") REFERENCES "lend_a_book"."user" ("id") ON UPDATE restrict ON DELETE cascade
);
COMMENT ON TABLE "lend_a_book"."group" IS E'Lending Groups that are used for isolating communities';
--
CREATE TRIGGER "set_lend_a_book_group_updated_at"
    BEFORE UPDATE
    ON "lend_a_book"."group"
    FOR EACH ROW
EXECUTE PROCEDURE "lend_a_book"."set_current_timestamp_updated_at"();
COMMENT ON TRIGGER "set_lend_a_book_group_updated_at" ON "lend_a_book"."group"
    IS 'trigger to set value of column "updated_at" to current timestamp on row update';
--
CREATE TABLE "lend_a_book"."membership"
(
    "id"         serial      NOT NULL,
    "group_id"   Integer     NOT NULL,
    "user_id"    integer     NOT NULL,
    "admin"      boolean     NOT NULL,
    "created_at" timestamptz NOT NULL DEFAULT now(),
    "updated_at" timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY ("id"),
    FOREIGN KEY ("user_id") REFERENCES "lend_a_book"."user" ("id") ON UPDATE restrict ON DELETE cascade,
    FOREIGN KEY ("group_id") REFERENCES "lend_a_book"."group" ("id") ON UPDATE restrict ON DELETE cascade
);
COMMENT ON TABLE "lend_a_book"."membership" IS E'Group Memberships';
--
CREATE TRIGGER "set_lend_a_book_membership_updated_at"
    BEFORE UPDATE
    ON "lend_a_book"."membership"
    FOR EACH ROW
EXECUTE PROCEDURE "lend_a_book"."set_current_timestamp_updated_at"();
COMMENT ON TRIGGER "set_lend_a_book_membership_updated_at" ON "lend_a_book"."membership"
    IS 'trigger to set value of column "updated_at" to current timestamp on row update';
--
CREATE OR REPLACE FUNCTION "lend_a_book"."on_insert_group"()
    RETURNS TRIGGER AS
$$
BEGIN
    INSERT INTO "lend_a_book"."membership"(group_id, user_id, admin) values (new.id, new.created_by, true);
    RETURN new;
END;
$$ LANGUAGE plpgsql;
--
CREATE TRIGGER "insert_admin_on_group_creation"
    AFTER INSERT
    ON "lend_a_book"."group"
    FOR EACH ROW
EXECUTE PROCEDURE "lend_a_book"."on_insert_group"();
COMMENT ON TRIGGER "insert_admin_on_group_creation" ON "lend_a_book"."group"
    IS 'Insert the group creator as admin when the group is created';
--