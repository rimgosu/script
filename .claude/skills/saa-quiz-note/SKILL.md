---
name: saa-quiz-note
description: Udemy의 AWS SAA(Solutions Architect Associate) 연습 문제 텍스트를 붙여넣으면, 문제·보기(빈 체크박스)·정답/해설(토글) 형식으로 정리해 rimnote "aws saa" 프로젝트에 저장한다. 사용자가 Udemy 연습 모드 문제 화면을 통째로 복사해 정리/저장을 요청할 때 사용.
---

# SAA Quiz Note

Udemy "Practice Exams | AWS Certified Solutions Architect Associate" 연습 모드 문제를
복습용 노트로 정리해 **rimnote "aws saa" 프로젝트**에 저장하는 스킬.

사용자가 Udemy 문제 화면 전체(질문, 보기, 정답, 전반적인 설명, 도메인 등)를 붙여넣고
"정리해줘 / 저장해줘 / rimnote에 만들어줘" 같은 요청을 하면 이 스킬을 따른다.

## 도구 준비

rimnote 도구가 deferred 상태면 먼저 로드한다 (한 번의 ToolSearch에 묶어서):

```
ToolSearch query "select:mcp__rimnote__list_projects,mcp__rimnote__set_active_project,mcp__rimnote__save_to_rimnote,mcp__rimnote__get_active_project"
```

저장 전 활성 프로젝트가 "aws saa"인지 `list_projects` 또는 `get_active_project`로 확인하고,
아니라면 `set_active_project`로 전환하거나 `save_to_rimnote`에 해당 `project_id`를 넘긴다.
(보통 "aws saa" 프로젝트가 이미 active 상태다.)

## 붙여넣은 텍스트에서 추출할 항목

- **질문 번호**: "질문 N:" 또는 "N/65" 형태 → 제목의 `[N/65]`에 사용
- **문제 본문**: 시나리오 설명 + 마지막 질문 문장. "(Select three)" 등 선택 개수도 보존
- **보기**: 각 선택지. 원문이 영어면 한국어로 자연스럽게 번역하되 서비스명·포트·속성명은 원문 유지
- **정답**: "정답" / "Correct option(s)"로 표시된 항목 → 보기의 A·B·C… 라벨로 매핑
- **해설**: "전반적인 설명"의 Correct/Incorrect options 내용
- **도메인**: "도메인" 항목 (예: Design Secure Architectures)
- **출처(References)**: 있으면 인용 블록으로 보존

## 출력 형식 (markdown)

제목: `[N/65] <간결한 한국어 제목>` (핵심 서비스/개념이 드러나게)

본문 구조:

```markdown
# [N/65] <제목>

**도메인:** <도메인>

## 📝 문제

<시나리오 본문 — 불릿으로 핵심 조건 정리>

<질문 문장> **(N개 선택)**  ← 복수 선택일 때만

## 보기

- [ ] A. <보기 1>
- [ ] B. <보기 2>
- [ ] C. <보기 3>
- [ ] D. <보기 4>
  (보기 개수만큼, 모두 빈 체크박스 `- [ ]` 로 — 정답을 노출하지 않는다)

<details><summary>✅ 정답 및 해설 보기</summary>

### 정답: **<라벨들, 예: C 또는 A, B, D>**

<정답 요약 — 필요하면 표로>

### 💡 해설

<왜 정답인지. 요구사항을 분해해 각 보기와 연결>

### 오답 노트
- ❌ **<라벨>** — <왜 틀렸는지>
  (오답마다 한 줄씩)

### 핵심 정리
<시험에 나올 키워드/함정 요약. 비교표가 유용하면 표로>

> 출처:
> - <References URL들>

</details>
```

## 규칙

- **보기 체크박스는 절대 미리 체크하지 않는다.** 정답이 보이면 복습이 안 된다.
- 정답·해설은 반드시 `<details><summary>…</summary>` **토글 안에 가린다.**
- 보기 라벨은 A, B, C… 순서로 붙이고, 정답/오답 노트에서 이 라벨로 참조한다.
- 영어 원문은 한국어로 번역하되 **서비스명(SQS, Kinesis…), 포트 번호, 속성명(Group ID…)은 원문 유지**.
- `save_to_rimnote` 호출 시 한국어 `keywords`를 함께 넣어 검색이 잘 되게 한다.
- 저장 후 노트 URL을 사용자에게 알려주고, 정답/함정 핵심을 2~3줄로 요약한다.
