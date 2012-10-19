/* May be useful for SQL Server:

	CREATE DATABASE lcmc_corpus
	COLLATE SQL_Latin1_General_CP1_CI_AS
	GO
*/


CREATE TABLE texts (
    id               VARCHAR(2) NOT NULL,
    type             VARCHAR(30),
    CONSTRAINT pk_texts PRIMARY KEY (id)
);


CREATE TABLE files (
    id               VARCHAR(3) NOT NULL,
    text_id          VARCHAR(2) NOT NULL,
    reference        NVARCHAR(500),
    CONSTRAINT pk_files PRIMARY KEY (id),
    CONSTRAINT fk_texts01 FOREIGN KEY (text_id) REFERENCES texts(id)
);


CREATE TABLE words (
    text_id          VARCHAR(2) NOT NULL,
    file_id          VARCHAR(3) NOT NULL,
    sentence_id      VARCHAR(5) NOT NULL,
    word_num         INTEGER,
    characters       NVARCHAR(16),
    part_of_speech   VARCHAR(4),  /* should be 2, but there are 6 records with extra whitespace: select * from words where length(part_of_speech) > 2 */
    token_type       CHAR(1),
    paragraph_num    INTEGER,
    running_idx    INTEGER,
    CONSTRAINT pk_words PRIMARY KEY (text_id, file_id, sentence_id, word_num),
    CONSTRAINT fk_texts02 FOREIGN KEY (text_id) REFERENCES texts(id),
    CONSTRAINT fk_files01 FOREIGN KEY (file_id) REFERENCES files(id)
);


CREATE TABLE full_sentences (
    text_id          VARCHAR(2) NOT NULL,
    file_id          VARCHAR(3) NOT NULL,
    sentence_id      VARCHAR(5) NOT NULL,
    paragraph_num    INTEGER,
    characters       NVARCHAR(500),
    CONSTRAINT pk_full_sentences PRIMARY KEY (text_id, file_id, sentence_id),
    CONSTRAINT fk_texts03 FOREIGN KEY (text_id) REFERENCES texts(id),
    CONSTRAINT fk_files02 FOREIGN KEY (file_id) REFERENCES files(id)
);


CREATE TABLE characters (
    text_id          VARCHAR(2) NOT NULL,
    file_id          VARCHAR(3) NOT NULL,
    sentence_id      VARCHAR(5) NOT NULL,
    word_num         INTEGER,
    char_num         INTEGER,
    character        NVARCHAR(2),   /* this should always be 1 */
    token_type       CHAR(1),
    CONSTRAINT pk_characters PRIMARY KEY (text_id, file_id, sentence_id, word_num, char_num),
    CONSTRAINT fk_words01 FOREIGN KEY (text_id, file_id, sentence_id, word_num) REFERENCES words(text_id, file_id, sentence_id, word_num)
);

CREATE TABLE pos (
    id  VARCHAR(2) NOT NULL,
    description  VARCHAR2(40),
    CONSTRAINT pk_pos PRIMARY KEY (id)
);


CREATE TABLE pinyin_words (
    text_id          VARCHAR(2) NOT NULL,
    file_id          VARCHAR(3) NOT NULL,
    sentence_id      VARCHAR(5) NOT NULL,
    word_num         INTEGER,
    characters       NVARCHAR(45),
    part_of_speech   VARCHAR(4),  /* should be 2, but there are 6 records with extra whitespace: select * from words where length(part_of_speech) > 2 */
    token_type       CHAR(1),
    paragraph_num    INTEGER,
    running_idx    INTEGER,
    CONSTRAINT pk_words PRIMARY KEY (text_id, file_id, sentence_id, word_num),
    CONSTRAINT fk_texts02 FOREIGN KEY (text_id) REFERENCES texts(id),
    CONSTRAINT fk_files01 FOREIGN KEY (file_id) REFERENCES files(id)
);


CREATE TABLE pinyin_full_sentences (
    text_id          VARCHAR(2) NOT NULL,
    file_id          VARCHAR(3) NOT NULL,
    sentence_id      VARCHAR(5) NOT NULL,
    paragraph_num    INTEGER,
    characters       NVARCHAR(2200),
    CONSTRAINT pk_full_sentences PRIMARY KEY (text_id, file_id, sentence_id),
    CONSTRAINT fk_texts03 FOREIGN KEY (text_id) REFERENCES texts(id),
    CONSTRAINT fk_files02 FOREIGN KEY (file_id) REFERENCES files(id)
);


CREATE TABLE pinyin_characters (
    text_id          VARCHAR(2) NOT NULL,
    file_id          VARCHAR(3) NOT NULL,
    sentence_id      VARCHAR(5) NOT NULL,
    word_num         INTEGER,
    char_num         INTEGER,
    character        NVARCHAR(7),   /* this should always be 1 */
    token_type       CHAR(1),
    CONSTRAINT pk_characters PRIMARY KEY (text_id, file_id, sentence_id, word_num, char_num),
    CONSTRAINT fk_words01 FOREIGN KEY (text_id, file_id, sentence_id, word_num) REFERENCES words(text_id, file_id, sentence_id, word_num)
);
