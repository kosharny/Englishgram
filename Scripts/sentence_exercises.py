"""Authored sentence-building additions; the last two rows are final-only."""
SENTENCES = {
1: [
 ('Emma is my neighbour.', 'Эмма — моя соседка.', 'Emma is not my neighbour.', 'Is Emma my neighbour?'),
 ('These flowers are fresh.', 'Эти цветы свежие.', 'These flowers are not fresh.', 'Are these flowers fresh?'),
 ('The kitchen is clean.', 'Кухня чистая.', 'The kitchen is not clean.', 'Is the kitchen clean?'),
 ('Your cousins are outside.', 'Твои двоюродные братья снаружи.', 'Your cousins are not outside.', 'Are your cousins outside?')],
2: [
 ('This is an old map.', 'Это старая карта.', 'This is not an old map.', 'Is this an old map?'),
 ('Nina is a dentist.', 'Нина — стоматолог.', 'Nina is not a dentist.', 'Is Nina a dentist?'),
 ('That is an empty box.', 'Это пустая коробка.', 'That is not an empty box.', 'Is that an empty box?'),
 ('The key is on the shelf.', 'Ключ на полке.', 'The key is not on the shelf.', 'Is the key on the shelf?')],
3: [
 ('Sophie teaches music.', 'Софи преподаёт музыку.', 'Sophie does not teach music.', 'Does Sophie teach music?'),
 ('Your parents grow vegetables.', 'Твои родители выращивают овощи.', 'Your parents do not grow vegetables.', 'Do your parents grow vegetables?'),
 ('Jack fixes bikes.', 'Джек ремонтирует велосипеды.', 'Jack does not fix bikes.', 'Does Jack fix bikes?'),
 ('The museum closes at five.', 'Музей закрывается в пять.', 'The museum does not close at five.', 'Does the museum close at five?')],
4: [
 ('Eva is making a sandwich.', 'Ева готовит сэндвич.', 'Eva is not making a sandwich.', 'Is Eva making a sandwich?'),
 ('The boys are cleaning their shoes.', 'Мальчики чистят свои ботинки.', 'The boys are not cleaning their shoes.', 'Are the boys cleaning their shoes?'),
 ('Mark is fixing the door.', 'Марк чинит дверь.', 'Mark is not fixing the door.', 'Is Mark fixing the door?'),
 ('Your friend is taking a photo.', 'Твой друг фотографирует.', 'Your friend is not taking a photo.', 'Is your friend taking a photo?')],
5: [
 ('There is a mirror in the hall.', 'В коридоре есть зеркало.', 'There is not a mirror in the hall.', 'Is there a mirror in the hall?'),
 ('There are four plates on the shelf.', 'На полке четыре тарелки.', 'There are not four plates on the shelf.', 'Are there four plates on the shelf?'),
 ('There is a bakery on this street.', 'На этой улице есть пекарня.', 'There is not a bakery on this street.', 'Is there a bakery on this street?'),
 ('There are two buses outside.', 'Снаружи два автобуса.', 'There are not two buses outside.', 'Are there two buses outside?')],
6: [
 ('Grace found her wallet.', 'Грейс нашла свой кошелёк.', 'Grace did not find her wallet.', 'Did Grace find her wallet?'),
 ('The visitors arrived yesterday.', 'Посетители приехали вчера.', 'The visitors did not arrive yesterday.', 'Did the visitors arrive yesterday?'),
 ('Daniel broke the cup.', 'Дэниел разбил чашку.', 'Daniel did not break the cup.', 'Did Daniel break the cup?'),
 ('Your team won the match.', 'Твоя команда выиграла матч.', 'Your team did not win the match.', 'Did your team win the match?')],
7: [
 ('Rose is going to learn to drive.', 'Роуз собирается учиться водить.', 'Rose is not going to learn to drive.', 'Is Rose going to learn to drive?'),
 ('The guests will arrive tomorrow.', 'Гости приедут завтра.', 'The guests will not arrive tomorrow.', 'Will the guests arrive tomorrow?'),
 ('Our class will visit the museum.', 'Наш класс посетит музей.', 'Our class will not visit the museum.', 'Will our class visit the museum?'),
 ('Your brother is going to sell his bike.', 'Твой брат собирается продать свой велосипед.', 'Your brother is not going to sell his bike.', 'Is your brother going to sell his bike?')],
8: [
 ('Molly can ride a horse.', 'Молли умеет ездить верхом.', 'Molly cannot ride a horse.', 'Can Molly ride a horse?'),
 ('We should check the address.', 'Нам стоит проверить адрес.', 'We should not check the address.', 'Should we check the address?'),
 ('You should open this message.', 'Тебе стоит открыть это сообщение.', 'You should not open this message.', 'Should you open this message?'),
 ('Your sister can use this camera.', 'Твоя сестра умеет пользоваться этой камерой.', 'Your sister cannot use this camera.', 'Can your sister use this camera?')],
9: [
 ('Alice has forgotten her password.', 'Элис забыла свой пароль.', 'Alice has not forgotten her password.', 'Has Alice forgotten her password?'),
 ('Our neighbours have moved away.', 'Наши соседи переехали.', 'Our neighbours have not moved away.', 'Have our neighbours moved away?'),
 ('James has repaired the shelf.', 'Джеймс починил полку.', 'James has not repaired the shelf.', 'Has James repaired the shelf?'),
 ('You have tried this soup before.', 'Ты уже пробовал этот суп.', 'You have not tried this soup before.', 'Have you tried this soup before?')],
10: [
 ('This luggage is heavy.', 'Этот багаж тяжёлый.', 'This luggage is not heavy.', 'Is this luggage heavy?'),
 ('These two pieces of advice are helpful.', 'Эти два совета полезны.', 'These two pieces of advice are not helpful.', 'Are these two pieces of advice helpful?'),
 ('The homework is difficult.', 'Домашняя работа сложная.', 'The homework is not difficult.', 'Is the homework difficult?'),
 ('Those cups are clean.', 'Те чашки чистые.', 'Those cups are not clean.', 'Are those cups clean?')],
11: [
 ('There is a lot of traffic today.', 'Сегодня много машин на дорогах.', 'There is not a lot of traffic today.', 'Is there a lot of traffic today?'),
 ('You need many stamps.', 'Тебе нужно много марок.', 'You do not need many stamps.', 'Do you need many stamps?'),
 ('We have enough sugar.', 'У нас достаточно сахара.', 'We do not have enough sugar.', 'Do we have enough sugar?'),
 ('There are too many cars here.', 'Здесь слишком много машин.', 'There are not too many cars here.', 'Are there too many cars here?')],
12: [
 ('This sofa is more comfortable.', 'Этот диван удобнее.', 'This sofa is not more comfortable.', 'Is this sofa more comfortable?'),
 ('My suitcase is lighter than yours.', 'Мой чемодан легче твоего.', 'My suitcase is not lighter than yours.', 'Is my suitcase lighter than yours?'),
 ('The blue jacket is the cheapest.', 'Синяя куртка самая дешёвая.', 'The blue jacket is not the cheapest.', 'Is the blue jacket the cheapest?'),
 ('Your new flat is larger than mine.', 'Твоя новая квартира больше моей.', 'Your new flat is not larger than mine.', 'Is your new flat larger than mine?')],
13: [
 ('Lily often takes the train.', 'Лили часто ездит на поезде.', 'Lily does not often take the train.', 'Does Lily often take the train?'),
 ('The neighbours are usually quiet.', 'Соседи обычно тихие.', 'The neighbours are not usually quiet.', 'Are the neighbours usually quiet?'),
 ('Oliver always brings lunch.', 'Оливер всегда приносит обед.', 'Oliver does not always bring lunch.', 'Does Oliver always bring lunch?'),
 ('You usually wake up early.', 'Ты обычно просыпаешься рано.', 'You do not usually wake up early.', 'Do you usually wake up early?')],
14: [
 ('If you practise, you will improve.', 'Если ты будешь практиковаться, ты станешь лучше.', 'If you practise, you will not improve.', 'Will you improve if you practise?'),
 ('If the shop is open, we will buy some fruit.', 'Если магазин будет открыт, мы купим фрукты.', 'If the shop is open, we will not buy any fruit.', 'Will we buy some fruit if the shop is open?'),
 ('If the road is closed, we will take a taxi.', 'Если дорога будет закрыта, мы возьмём такси.', 'If the road is closed, we will not take a taxi.', 'Will we take a taxi if the road is closed?'),
 ('You will come if the weather is good.', 'Ты придёшь, если будет хорошая погода.', 'You will not come if the weather is good.', 'Will you come if the weather is good?')],
15: [
 ('Freya enjoys baking cakes.', 'Фрейе нравится печь торты.', 'Freya does not enjoy baking cakes.', 'Does Freya enjoy baking cakes?'),
 ('The students plan to study abroad.', 'Студенты планируют учиться за границей.', 'The students do not plan to study abroad.', 'Do the students plan to study abroad?'),
 ('Oscar wants to become a teacher.', 'Оскар хочет стать учителем.', 'Oscar does not want to become a teacher.', 'Does Oscar want to become a teacher?'),
 ('Your friends enjoy hiking.', 'Твоим друзьям нравится ходить в походы.', 'Your friends do not enjoy hiking.', 'Do your friends enjoy hiking?')],
16: [
 ('Zoe was choosing a dress.', 'Зои выбирала платье.', 'Zoe was not choosing a dress.', 'Was Zoe choosing a dress?'),
 ('The nurses were helping a patient.', 'Медсёстры помогали пациенту.', 'The nurses were not helping a patient.', 'Were the nurses helping a patient?'),
 ('The driver was checking the engine.', 'Водитель проверял двигатель.', 'The driver was not checking the engine.', 'Was the driver checking the engine?'),
 ('Your parents were travelling in Spain.', 'Твои родители путешествовали по Испании.', 'Your parents were not travelling in Spain.', 'Were your parents travelling in Spain?')],
17: [
 ('Clara has been practising the violin.', 'Клара занималась игрой на скрипке.', 'Clara has not been practising the violin.', 'Has Clara been practising the violin?'),
 ('The builders have been repairing the roof.', 'Строители ремонтировали крышу.', 'The builders have not been repairing the roof.', 'Have the builders been repairing the roof?'),
 ('Ethan has been preparing for the interview.', 'Итан готовился к собеседованию.', 'Ethan has not been preparing for the interview.', 'Has Ethan been preparing for the interview?'),
 ('Your sister has been learning Italian.', 'Твоя сестра учит итальянский уже какое-то время.', 'Your sister has not been learning Italian.', 'Has your sister been learning Italian?')],
18: [
 ('If I had a balcony, I would grow tomatoes.', 'Если бы у меня был балкон, я бы выращивал помидоры.', 'If I had a balcony, I would not grow tomatoes.', 'Would I grow tomatoes if I had a balcony?'),
 ('If the tickets were cheaper, we would buy them.', 'Если бы билеты были дешевле, мы бы их купили.', 'If the tickets were cheaper, we would not buy them.', 'Would we buy the tickets if they were cheaper?'),
 ('If I owned a boat, I would sell it.', 'Если бы у меня была лодка, я бы её продал.', 'If I owned a boat, I would not sell it.', 'Would I sell the boat if I owned one?'),
 ('You would join us if you had a day off.', 'Ты бы присоединился к нам, если бы у тебя был выходной.', 'You would not join us if you had a day off.', 'Would you join us if you had a day off?')],
19: [
 ('The parcel was delivered on Friday.', 'Посылку доставили в пятницу.', 'The parcel was not delivered on Friday.', 'Was the parcel delivered on Friday?'),
 ('These vegetables are grown locally.', 'Эти овощи выращивают здесь, в регионе.', 'These vegetables are not grown locally.', 'Are these vegetables grown locally?'),
 ('The meeting was cancelled yesterday.', 'Встречу отменили вчера.', 'The meeting was not cancelled yesterday.', 'Was the meeting cancelled yesterday?'),
 ('The documents will be checked today.', 'Документы проверят сегодня.', 'The documents will not be checked today.', 'Will the documents be checked today?')],
20: [
 ('The woman who owns this cafe is friendly.', 'Женщина, которая владеет этим кафе, дружелюбная.', 'The woman who owns this cafe is not friendly.', 'Is the woman who owns this cafe friendly?'),
 ('The shoes that I ordered are comfortable.', 'Обувь, которую я заказал, удобная.', 'The shoes that I ordered are not comfortable.', 'Are the shoes that I ordered comfortable?'),
 ('The artist whose work we saw is famous.', 'Художник, чьи работы мы видели, знаменит.', 'The artist whose work we saw is not famous.', 'Is the artist whose work we saw famous?'),
 ('This is the village where your aunt lives.', 'Это деревня, где живёт твоя тётя.', 'This is not the village where your aunt lives.', 'Is this the village where your aunt lives?')],
}

VARIATIONS = {
1: [('changePerson','Замените I на we','I am hungry.','We are hungry.','С we используйте are вместо am.'), ('shortAnswer','Дайте короткий отрицательный ответ','Is your brother a student?','No, he is not.','Your brother заменяется на he. В отрицательном коротком ответе сохраняется is и добавляется not.')],
2: [('wordOrder','Добавьте подходящий артикль и соберите фразу','My uncle is dentist.','My uncle is a dentist.','Перед названием профессии в единственном числе нужен a/an. Dentist начинается с согласного звука.'), ('wordOrder','Замените apple на banana и измените артикль','This is an apple.','This is a banana.','Banana начинается с согласного звука, поэтому an меняется на a.')],
3: [('changePerson','Замените they на she','They carry heavy bags.','She carries heavy bags.','После she глагол получает -s/-es. Согласная + y: carry → carries.'), ('shortAnswer','Дайте короткий положительный ответ','Does your uncle speak French?','Yes, he does.','Your uncle заменяется на he. В коротком ответе повторяется does, а не смысловой глагол speak.')],
4: [('changePerson','Замените he на they','He is sitting by the window.','They are sitting by the window.','С they нужна форма are; sitting не меняется.'), ('shortAnswer','Дайте короткий отрицательный ответ','Are the students listening?','No, they are not.','The students заменяется на they. Повторяется are, а не listening.')],
5: [('wordOrder','Замените a chair на three chairs','There is a chair in the kitchen.','There are three chairs in the kitchen.','Три стула — множественное число, поэтому there are.'), ('shortAnswer','Дайте короткий положительный ответ','Is there a library near here?','Yes, there is.','В ответе на вопрос о наличии сохраняется there, а не it.')],
6: [('wordOrder','Перенесите действие в прошлое: замените every day на yesterday','I catch the bus every day.','I caught the bus yesterday.','У catch неправильная прошедшая форма caught. Yesterday задаёт завершённое прошлое.'), ('shortAnswer','Дайте короткий отрицательный ответ','Did the guests stay overnight?','No, they did not.','В коротком ответе на Did…? используется did. The guests заменяется на they.')],
7: [('changePerson','Замените I на she','I am going to start a course.','She is going to start a course.','Форма be меняется с am на is. Going to start сохраняется.'), ('shortAnswer','Дайте короткий положительный ответ','Will the package arrive today?','Yes, it will.','The package заменяется на it. Will повторяется без arrive.')],
8: [('changePerson','Замените I на he','I can speak German.','He can speak German.','Can не меняется по лицам; после него начальная форма speak.'), ('shortAnswer','Дайте короткий отрицательный ответ','Can the children stay here?','No, they cannot.','The children заменяется на they. Cannot пишется слитно.')],
9: [('changePerson','Замените we на she','We have booked a table.','She has booked a table.','С she используется has. Booked остаётся третьей формой.'), ('shortAnswer','Дайте короткий положительный ответ','Have your friends arrived safely?','Yes, they have.','В коротком ответе повторяется have. Your friends заменяется на they.')],
10: [('wordOrder','Выразите количество через pieces of','I have three advices.','I have three pieces of advice.','Advice неисчисляемое. Множественное число получает единица pieces, а advice остаётся без -s.'), ('wordOrder','Исправьте согласование и соберите фразу','This equipment are expensive.','This equipment is expensive.','Equipment неисчисляемое и согласуется с is.')],
11: [('wordOrder','Спросите о количестве воды: используйте how much','We need water for the trip.','How much water do we need for the trip?','Water неисчисляемое, поэтому how much. Для вопроса с need и we используется do.'), ('wordOrder','Спросите о количестве билетов: используйте how many','They need tickets for the concert.','How many tickets do they need for the concert?','Tickets — исчисляемое множественное число. Порядок: how many tickets + do + they + need.')],
12: [('wordOrder','Сравните с помощью than: начните с Mount Snowdon','Mount Snowdon is high. This hill is low.','Mount Snowdon is higher than this hill.','Короткое high образует higher. Than вводит второй объект.'), ('wordOrder','Исправьте двойную сравнительную степень','This route is more shorter than ours.','This route is shorter than ours.','Нельзя одновременно использовать more и окончание -er.')],
13: [('wordOrder','Добавьте usually в нейтральной позиции','My sister is cheerful.','My sister is usually cheerful.','С to be наречие обычно стоит после связки is.'), ('wordOrder','Добавьте often в нейтральной позиции','We eat dinner together.','We often eat dinner together.','С обычным глаголом наречие ставится перед ним: often eat.')],
14: [('combineSentences','Объедините через if. Начните с If и используйте will в результате','You save enough money. You buy a new laptop.','If you save enough money, you will buy a new laptop.','После if Present Simple. В главной части will + buy.'), ('wordOrder','Замените unless на if … not, начните с If','Unless we leave soon, we will be late.','If we do not leave soon, we will be late.','Unless здесь означает if … not. С we отрицание образуется через do not.')],
15: [('wordOrder','Добавьте цель через to и начните с I went','I went to the market. I wanted to buy fruit.','I went to the market to buy fruit.','To buy выражает цель: пошёл, чтобы купить.'), ('wordOrder','Исправьте форму после предлога','She is interested in to learn Spanish.','She is interested in learning Spanish.','После предлога in нужна форма -ing: learning.')],
16: [('changePerson','Замените she на we','She was crossing the bridge.','We were crossing the bridge.','С we нужна форма were, crossing сохраняется.'), ('shortAnswer','Дайте короткий положительный ответ','Was your mother working at eight?','Yes, she was.','Your mother заменяется на she. В ответе повторяется was.')],
17: [('changePerson','Замените they на he','They have been saving money.','He has been saving money.','С he нужно has. Been saving сохраняется.'), ('shortAnswer','Дайте короткий отрицательный ответ','Has your father been working all night?','No, he has not.','В коротком ответе повторяется has. Been working не повторяется.')],
18: [('combineSentences','Объедините как воображаемое условие. Начните с If I','I do not have a bigger kitchen. I cannot buy a larger table.','If I had a bigger kitchen, I could buy a larger table.','Had обозначает воображаемое условие сейчас. Could выражает возможность купить стол.'), ('wordOrder','Дайте совет: начните с If I were you','You need a break.','If I were you, I would take a break.','If I were you — устойчивая модель совета. В главной части would + начальная форма.')],
19: [('wordOrder','Преобразуйте в пассив. Начните с The invitations, исполнителя не указывайте','They printed the invitations yesterday.','The invitations were printed yesterday.','Дополнение invitations становится подлежащим. Множественное число и прошлое требуют were + V3.'), ('wordOrder','Преобразуйте в актив. Начните с A local chef','The meal was prepared by a local chef.','A local chef prepared the meal.','Исполнитель становится подлежащим. Past Simple сохраняет время исходного предложения.')],
20: [('combineSentences','Объедините с who. Начните с The nurse','The nurse helped me. She was patient.','The nurse who helped me was patient.','Who заменяет подлежащее придаточного. Дополнительное she не нужно.'), ('combineSentences','Объедините с that. Начните с The camera','I bought a camera. The camera is expensive.','The camera that I bought is expensive.','That заменяет дополнение bought. Подлежащее придаточного — I.')],
}
