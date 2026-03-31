# educabR: Download and Process Brazilian Education Data from INEP

Download and process public education data from INEP (Instituto Nacional
de Estudos e Pesquisas Educacionais Anísio Teixeira). Provides functions
to access microdata from the School Census (Censo Escolar), ENEM (Exame
Nacional do Ensino Médio), SAEB (Sistema de Avaliação da Educação
Básica), Higher Education Census (Censo da Educação Superior), ENADE
(Exame Nacional de Desempenho dos Estudantes), ENCCEJA (Exame Nacional
para Certificação de Competências de Jovens e Adultos), IDD (Indicador
de Diferença entre os Desempenhos Observado e Esperado), IDEB (Índice de
Desenvolvimento da Educação Básica), and other educational datasets.
Returns data in tidy format ready for analysis. Data source: INEP Open
Data Portal
<https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos>.

The educabR package provides functions to download and process public
education data from INEP (Instituto Nacional de Estudos e Pesquisas
Educacionais Anísio Teixeira). It offers easy access to microdata from:

- **School Census (Censo Escolar)**: Annual data on schools, enrollment,
  teachers, and classes in basic education

- **ENEM**: Data from the National High School Exam

- **SAEB**: Basic Education Assessment System (student performance)

- **Higher Education Census (Censo da Educação Superior)**: Annual data
  on institutions, courses, students, and faculty in higher education

- **ENADE**: National Student Performance Exam (higher education)

- **IDD**: Value-added indicator for undergraduate courses

- **ENCCEJA**: Youth and Adult Education Certification Exam

- **IDEB**: Basic Education Development Index

All functions return data in tidy format, ready for analysis with
tidyverse tools.

## Main functions

**School Census:**

- [`get_censo_escolar()`](https://sidneybissoli.github.io/educabR/reference/get_censo_escolar.md):
  Download School Census microdata

**ENEM:**

- [`get_enem()`](https://sidneybissoli.github.io/educabR/reference/get_enem.md):
  Download ENEM microdata

**SAEB:**

- [`get_saeb()`](https://sidneybissoli.github.io/educabR/reference/get_saeb.md):
  Download SAEB microdata

**Higher Education Census:**

- [`get_censo_superior()`](https://sidneybissoli.github.io/educabR/reference/get_censo_superior.md):
  Download Higher Education Census microdata

**ENADE:**

- [`get_enade()`](https://sidneybissoli.github.io/educabR/reference/get_enade.md):
  Download ENADE microdata

**IDD:**

- [`get_idd()`](https://sidneybissoli.github.io/educabR/reference/get_idd.md):
  Download IDD data

**ENCCEJA:**

- [`get_encceja()`](https://sidneybissoli.github.io/educabR/reference/get_encceja.md):
  Download ENCCEJA microdata

**IDEB:**

- [`get_ideb()`](https://sidneybissoli.github.io/educabR/reference/get_ideb.md):
  Download IDEB data

## Cache system

The package implements a local cache system to avoid repeated downloads.
Use
[`set_cache_dir()`](https://sidneybissoli.github.io/educabR/reference/set_cache_dir.md)
to configure a persistent cache directory. See
[`get_cache_dir()`](https://sidneybissoli.github.io/educabR/reference/get_cache_dir.md)
to check the current cache location.

## Data source

All data is downloaded from INEP's official portal:
<https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/microdados>

## See also

Useful links:

- <https://github.com/SidneyBissoli/educabR>

- <https://sidneybissoli.github.io/educabR/>

- Report bugs at <https://github.com/SidneyBissoli/educabR/issues>

## Author

**Maintainer**: Sidney da Silva Pereira Bissoli <sbissoli76@gmail.com>
([ORCID](https://orcid.org/0009-0001-0442-3700))
