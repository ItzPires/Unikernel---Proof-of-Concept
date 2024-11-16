TARGET = hello

SRCS = main.c

CC = gcc

CFLAGS = -Wall -Wextra -std=c11 -static

$(TARGET): $(SRCS)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRCS)

clean:
	rm -f $(TARGET)
