BEGIN;

ALTER TABLE idea ADD COLUMN claimed_by bigint;

ALTER TABLE idea ADD COLUMN instant_answer_id text;

ALTER TABLE idea ADD CONSTRAINT idea_fk_instant_answer_id FOREIGN KEY (instant_answer_id)
  REFERENCES instant_answer (id) ON DELETE RESTRICT ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE idea ADD CONSTRAINT idea_fk_claimed_by FOREIGN KEY (claimed_by)
  REFERENCES users (id) ON DELETE RESTRICT ON UPDATE CASCADE DEFERRABLE;

COMMIT;

