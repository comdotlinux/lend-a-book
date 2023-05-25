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
-- https://stackoverflow.com/a/67009586/3331412
-- https://www.postgresql.org/docs/13/sql-createfunction.html
-- https://stackoverflow.com/questions/3970795/how-do-you-create-a-random-string-thats-suitable-for-a-session-id-in-postgresql/3972983#3972983
Create or replace function "lend_a_book"."random_string"(ofLength integer) returns text as
$$
declare
    chars  text[]  := '{0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z}';
    result text    := '';
begin
    if ofLength < 0 then
        raise exception 'Given length cannot be less than 0';
    end if;
    for _ in 1..ofLength
        loop
            result := result || chars[ceil(61 * random())];
        end loop;
    return result;
end;
$$ language plpgsql;
COMMENT ON FUNCTION "lend_a_book"."random_string" IS E'This Function is used to generate a string of a specified length. Currently used in generating the invitation codes.';
--
CREATE TABLE "lend_a_book"."invitation"
(
    "id"         serial      NOT NULL,
    "name"       text        NOT NULL,
    "code"       text        NOT NULL default "lend_a_book"."random_string"(14),
    "group" integer NOT NULL,
    "created_by" integer     NOT NULL,
    "active"     boolean     NOT NULL,
    "created_at" timestamptz NOT NULL DEFAULT now(),
    "updated_at" timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY ("id"),
    FOREIGN KEY ("created_by") REFERENCES "lend_a_book"."user" ("id") ON UPDATE cascade ON DELETE cascade,
    FOREIGN KEY ("group") REFERENCES "lend_a_book"."group" ("id") ON UPDATE cascade ON DELETE cascade
);
COMMENT ON TABLE "lend_a_book"."invitation" IS E'Invitations created to join a group.';
--
CREATE TRIGGER "set_lend_a_book_invitation_updated_at"
    BEFORE UPDATE
    ON "lend_a_book"."invitation"
    FOR EACH ROW
EXECUTE PROCEDURE "lend_a_book"."set_current_timestamp_updated_at"();
COMMENT ON TRIGGER "set_lend_a_book_invitation_updated_at" ON "lend_a_book"."invitation"
    IS 'trigger to set value of column "updated_at" to current timestamp on row update';
CREATE TABLE "lend_a_book"."return_val"
(
    success         bool,
    translation_key text
);
COMMENT ON TABLE "lend_a_book"."return_val" IS E'This table is tracked by hasura. We need it only to define the return type of operations since hasura is not propagating the exceptions raised from postgres. The table itself will never contain any rows';
--
CREATE TABLE "lend_a_book"."invitation_acceptance"
(
    "id"          serial      NOT NULL,
    "invitation"  integer     NOT NULL,
    "accepted_by" integer     NOT NULL,
    "created_at"  timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY ("id"),
    FOREIGN KEY ("invitation") REFERENCES "lend_a_book"."invitation" ("id") ON UPDATE cascade ON DELETE cascade,
    FOREIGN KEY ("accepted_by") REFERENCES "lend_a_book"."user" ("id") ON UPDATE cascade ON DELETE cascade,
    UNIQUE ("invitation", "accepted_by")
);
COMMENT ON TABLE "lend_a_book"."invitation_acceptance" IS E'User Accepting an invitation is added here, because users usually can abuse the invitation, one person can only join using an invitation just once else needs a new invitation.';
--
CREATE OR REPLACE FUNCTION "lend_a_book"."accept_invitation"(hasura_session json, invitation_code text)
    RETURNS SETOF "lend_a_book"."return_val"
AS
$$
DECLARE
    -- parsing the userId from the caller
    user_id int := (hasura_session ->> 'x-hasura-user-id')::int;
    invitation_row "lend_a_book"."invitation"%rowtype;
    invitation_acceptance_row "lend_a_book"."invitation_acceptance"%rowtype;
BEGIN

    SELECT * FROM "lend_a_book"."invitation" i WHERE i.code = invitation_code INTO invitation_row;

    IF invitation_row IS NULL THEN
        RAISE WARNING 'Cannot accept invitation, incorrect code';
        RETURN QUERY SELECT false, 'backend.error.invitation-code-already-used';
        RETURN;
    END IF;

    SELECT * FROM "lend_a_book"."invitation_acceptance" WHERE invitation = invitation_row.id AND accepted_by = user_id INTO invitation_acceptance_row;

    IF invitation_acceptance_row IS NOT NULL THEN
        RAISE WARNING 'Cannot accept invitation, user already accepted code';
        RETURN QUERY SELECT false, 'backend.error.invitation-code-already-used';
        RETURN;
    END IF;

    INSERT INTO "lend_a_book"."invitation_acceptance" (invitation, accepted_by) VALUES (invitation_row.id, user_id);
    INSERT INTO "lend_a_book"."membership" (group_id, user_id, admin) VALUES (invitation_row.group, user_id, false);

    RETURN QUERY SELECT true, 'backend.success.invitation_accepted';
    RETURN;
END
$$
    LANGUAGE plpgsql;

COMMENT ON FUNCTION "lend_a_book"."accept_invitation"
    IS 'Function that checks that an invitation code is correct an not previously accepted already.';