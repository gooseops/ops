# Needs mor help than this
def help_function ():
    print("This is the help you always needed")
    exit(0)

init = input("\nWe are here to play Madlibs!  Are you familiar with this game? ")

if init.lower() == "yes":
    print("Great! Let's get started")
elif init.lower() == "no":
    help_function()
else:
    print("\nThat was a 'yes' or 'no' question you imbecile. Please respond in kind")
    print("or leave this program alone because it is obvious you have no clue")
    print("what you are doing...that is all...")
    exit(1)

name = input("Please enter a name: ")
noun = input("Please enter a noun: ")
city = input("Please enter a city: ")

print("\nHere is your Madlib with your inputs entered in the blanks!")
print("\nPlease send [{}] a [{}].  He now lives in [{}]" .format(name,noun,city))
