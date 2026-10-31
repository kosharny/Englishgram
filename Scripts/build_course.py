"""Compile the authored, offline course into validated bundle resources."""
import json
from pathlib import Path
from course_a1 import TOPICS as A1
from course_a2 import TOPICS as A2
from course_b1 import TOPICS as B1
from lesson_expansions import EXPANSIONS
from sentence_exercises import SENTENCES, VARIATIONS

ROOT = Path(__file__).resolve().parents[1]

def sentence(row):
    marked, ru = row.split(' :: ')
    before, rest = marked.split('[')
    choices, after = rest.split(']')
    options = choices.split('|')
    return before + options[0] + after, ru, before + '___' + after, options, before + options[1] + after

def tokens(text):
    return text.rstrip('.!?').split()

def build(seed, order, level):
    name, subtitle, intro, uses, formulas, tip, mistake, signals, rows, transforms = seed
    ident = f'topic-{order:02}'
    blocks = []
    def block(kind, title, text, detail=None):
        blocks.append(dict(id=f'{ident}-b{len(blocks)}', kind=kind, title=title, text=text, detail=detail))
    block('text', 'Что это?', intro)
    block('text', 'Когда используем?', uses)
    for title, formula in formulas:
        block('formula', title, formula)
    for row in rows[:3]:
        en, ru, *_ = sentence(row)
        block('example', 'Пример', en, ru)
    block('tip', 'Важно', tip)
    wrong, right, why = mistake
    block('mistake', 'Частая ошибка', wrong, right + '\n' + why)
    block('words', 'Слова и ориентиры', signals)
    for kind, title, body, detail in EXPANSIONS[order]:
        block(kind, title, body, detail)
    block('summary', 'Запомните главное', intro + '\n\n' + tip + '\n\n' + why)
    questions=[]
    def q(stage, kind, prompt, answer, explanation, options=None, instruction=None, skill=None):
        instructions={'multipleChoice':'Выберите правильный вариант', 'translation':'Переведите предложение', 'wordOrder':'Составьте предложение', 'findMistake':'Выберите исправленное предложение', 'trueFalse':'Верно ли построено предложение?', 'makeNegative':'Сделайте предложение отрицательным', 'makeQuestion':'Сделайте вопрос из утверждения'}
        questions.append(dict(id=f'{ident}-q{len(questions)+1:02}',topicID=ident,stage=stage,kind=kind,
            difficulty=1 if kind=='multipleChoice' else 2 if kind in ['translation','wordOrder'] else 3,
            instruction=instruction or instructions.get(kind, 'Составьте предложение'),prompt=prompt,answer=answer,
            explanation=explanation,options=options or [],tokens=tokens(answer) if kind in ['translation','wordOrder','makeNegative','makeQuestion','changePerson','shortAnswer','combineSentences'] else [],skill=skill or ('Порядок слов' if kind in ['translation','wordOrder'] else subtitle)))
    for row in rows[:8]:
        en,ru,gap,options,bad=sentence(row)
        q(1,'multipleChoice',gap,options[0],f'Правильно: {en} {tip}',options)
    for row in rows[:8]:
        en,ru,*_=sentence(row)
        q(2,'translation',ru,en,f'{en} {intro}')
    for i,row in enumerate(rows[:8]):
        en,ru,gap,options,bad=sentence(row)
        if i<2:
            kind,source,answer,why=transforms[i]
            q(3,kind,source,answer,why,skill='Отрицание' if kind=='makeNegative' else 'Вопросы')
        elif i<4:
            q(3,'trueFalse',bad,'Неверно',f'Правильно: {en} {tip}', ['Верно','Неверно'])
        elif i<6:
            q(3,'wordOrder',ru,en,f'{en} {tip}')
        else:
            q(3,'findMistake',bad,en,f'{en} {tip}',[en,bad, gap.replace('___',options[2])])
    for i,row in enumerate(rows[8:12]):
        en,ru,gap,options,bad=sentence(row)
        q(4,'multipleChoice',gap,options[0],f'{en} {tip}',options)
    for row in rows[12:16]:
        en,ru,*_=sentence(row)
        q(4,'translation',ru,en,f'{en} {tip}')
    for i,row in enumerate(rows[8:15]):
        en,ru,gap,options,bad=sentence(row)
        if i<4:
            q(4,'wordOrder',bad,en,f'Исправление: {en} {tip}', instruction='Исправьте ошибку: соберите верное предложение', skill='Исправление ошибок')
        else:
            q(4,'trueFalse',en if i%2==0 else bad,'Верно' if i%2==0 else 'Неверно',f'{en} {tip}', ['Верно','Неверно'])
    for row in rows[:2]:
        en, ru, gap, options, bad = sentence(row)
        q(1, 'wordOrder', bad, en, f'{en} {tip}', instruction='Исправьте ошибку: составьте предложение из слов', skill='Исправление ошибок')
    for en, ru, negative, question in SENTENCES[order][:2]:
        q(2, 'translation', ru, en, f'{en} {tip}')
    first, second, final_negative, final_question = SENTENCES[order]
    q(3, 'makeNegative', first[0], first[2], f'{first[2]} {tip}', instruction='Сделайте главную часть отрицательной' if order in [14, 18, 20] else None, skill='Отрицание')
    q(3, 'makeQuestion', second[0], second[3], f'{second[3]} {tip}', skill='Вопросы')
    for kind, instruction, prompt, answer, explanation in VARIATIONS[order]:
        q(3, kind, prompt, answer, explanation, instruction=instruction, skill={'changePerson':'Согласование', 'shortAnswer':'Короткие ответы', 'combineSentences':'Связь предложений'}.get(kind, 'Порядок слов'))
    q(4, 'makeNegative', final_negative[0], final_negative[2], f'{final_negative[2]} {tip}', instruction='Сделайте главную часть отрицательной' if order in [14, 18, 20] else None, skill='Отрицание')
    q(4, 'makeQuestion', final_question[0], final_question[3], f'{final_question[3]} {tip}', skill='Вопросы')
    for index, item in enumerate(questions):
        if item['kind'] == 'translation' and index % 3 == 0 and 'not' not in item['tokens']:
            item['tokens'].append('not')
    assert len(questions)==49
    assert len(rows)==16
    assert len({q['id'] for q in questions})==49
    prior={q['prompt'] for q in questions if q['stage']!=4}
    assert not prior.intersection(q['prompt'] for q in questions if q['stage']==4), (name, prior.intersection(q['prompt'] for q in questions if q['stage']==4))
    for item in questions:
        if item['options']: assert len(set(item['options']))==len(item['options'])
    return dict(id=ident,order=order,title=name,level=level,subtitle=subtitle,minutes={'A1':18,'A2':22,'B1':25}[level],lecture=blocks,questions=questions)

if __name__=='__main__':
    order=1
    for level,seeds in [('A1',A1),('A2',A2),('B1',B1)]:
        result=[]
        for seed in seeds:
            result.append(build(seed,order,level)); order+=1
        (ROOT/'Englishgram'/'Data'/f'{level}CourseEG.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
    print(f'Validated {order-1} topics, {(order-1)*49} questions.')
