/* Summarize word frequencies */

DROP TABLE IF EXISTS frequencies;

CREATE TABLE frequencies (
    rank        INTEGER,
    characters  NVARCHAR(10),
    raw_ct      INTEGER,
    freq_per_million NUMBER,
    CONSTRAINT pk_frequencies PRIMARY KEY (rank),
    CONSTRAINT uq_frequencies_characters UNIQUE (characters),
    CONSTRAINT fk_words_02 FOREIGN KEY (characters) REFERENCES words(characters)
);

DROP TABLE IF EXISTS tmp_freq;

/* temporary tables have rowids from 1..n */
create temporary table tmp_freq as
SELECT characters, COUNT('x') AS raw_ct, NULL
    FROM words
   WHERE token_type = 'w'
     --AND characters REGEXP '^[\x{3400}-\x{4DBF}\x{4E00}-\x{9FFF}\x{F900}-\x{FAFF}\x{00b7}]+$'
     AND is_cjk = 'Y'
   GROUP BY characters ORDER BY count('x') DESC, characters ASC
;

insert into frequencies (rank, characters, raw_ct, freq_per_million)
  select rowid, characters, raw_ct, ROUND(1.0e6 * raw_ct/(SELECT sum(raw_ct) FROM tmp_freq), 2)
    from tmp_freq
;


DROP TABLE tmp_freq;


/* Summarize character frequencies */


DROP TABLE IF EXISTS char_frequencies;

CREATE TABLE char_frequencies (
    rank        INTEGER,
    character  NVARCHAR(1),
    raw_ct      INTEGER,
    freq_per_million NUMBER,
    CONSTRAINT pk_char_frequencies PRIMARY KEY (rank),
    CONSTRAINT uq_char_frequencies_characters UNIQUE (character),
    CONSTRAINT fk_characters_01 FOREIGN KEY (character) REFERENCES characters(character)
);

DROP TABLE IF EXISTS tmp_freq;

/* temporary tables have rowids from 1..n */
create temporary table tmp_freq as
SELECT character, COUNT('x') AS raw_ct, NULL
    FROM characters
   WHERE token_type = 'w'
     --AND characters REGEXP '^[\x{3400}-\x{4DBF}\x{4E00}-\x{9FFF}\x{F900}-\x{FAFF}\x{00b7}]+$'
     AND is_cjk = 'Y'
   GROUP BY character ORDER BY count('x') DESC, character ASC
;

insert into char_frequencies (rank, character, raw_ct, freq_per_million)
  select rowid, character, raw_ct, ROUND(1.0e6 * raw_ct/(SELECT sum(raw_ct) FROM tmp_freq), 2)
    from tmp_freq
;


DROP TABLE tmp_freq;


/* Summarize number of characters per section */

ALTER TABLE texts ADD COLUMN ch_word_ct  INTEGER;

UPDATE texts SET ch_word_ct = (
SELECT COUNT(characters) FROM words
WHERE token_type = 'w'
  --AND characters REGEXP '^[\x{3400}-\x{4DBF}\x{4E00}-\x{9FFF}\x{F900}-\x{FAFF}\x{00b7}]+$'
  AND is_cjk = 'Y'
  AND text_id = texts.id
GROUP BY text_id
);


