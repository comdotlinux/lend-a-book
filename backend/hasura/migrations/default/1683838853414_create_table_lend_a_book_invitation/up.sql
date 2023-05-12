CREATE TABLE "lend_a_book"."invitation" ("id" serial NOT NULL, "name" text NOT NULL, "code" text NOT NULL, "created_by" integer NOT NULL, "active" boolean NOT NULL, "created_at" timestamptz NOT NULL DEFAULT now(), "updated_at" timestamptz NOT NULL DEFAULT now(), PRIMARY KEY ("id") , FOREIGN KEY ("created_by") REFERENCES "lend_a_book"."user"("id") ON UPDATE cascade ON DELETE cascade);COMMENT ON TABLE "lend_a_book"."invitation" IS E'Invitations created to join a group.';
CREATE OR REPLACE FUNCTION "lend_a_book"."set_current_timestamp_updated_at"()
RETURNS TRIGGER AS $$
DECLARE
  _new record;
BEGIN
  _new := NEW;
  _new."updated_at" = NOW();
  RETURN _new;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER "set_lend_a_book_invitation_updated_at"
BEFORE UPDATE ON "lend_a_book"."invitation"
FOR EACH ROW
EXECUTE PROCEDURE "lend_a_book"."set_current_timestamp_updated_at"();
COMMENT ON TRIGGER "set_lend_a_book_invitation_updated_at" ON "lend_a_book"."invitation"
IS 'trigger to set value of column "updated_at" to current timestamp on row update';
