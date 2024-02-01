import random

random_integer = random.randrange(101)
print(random_integer)

print('Please guess a positive integer between 0 and 100.')

guess = int(input())
print(guess, 'and', random_integer)
while (guess != random_integer):
    print('Please guess again.')
    guess = int(input())
else:
    print('Congratulations! You figured it out!')
