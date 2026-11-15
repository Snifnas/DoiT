-- Tighten quests that still read too much like chores.
UPDATE public.doit_quests
SET title='Turn your room into a game show',
    description='Stage three silly mini-games using objects you own, set up an absurd host desk and photograph the whole game-show set. You can play solo or challenge a friend.',
    minutes=65,
    xp=160
WHERE group_id IS NULL AND active=true AND title='Create the ultimate game-night kit';

UPDATE public.doit_quests
SET title='The object-rescue transformation',
    description='Pick an old or forgotten harmless object and give it a dramatic second life. Stage a proper before-and-after photo like a restoration show.',
    minutes=15,
    xp=35
WHERE group_id IS NULL AND active=true AND title='Rescue a forgotten object';

UPDATE public.doit_quests
SET title='Sneaker makeover challenge',
    description='Give an old pair of shoes a careful cleaning and stage a dramatic before-and-after shot like a sneaker-restoration video.',
    minutes=20,
    xp=40
WHERE group_id IS NULL AND active=true AND title='Bring a pair of shoes back to life';