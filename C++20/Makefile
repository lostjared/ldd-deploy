CXXFLAGS = -std=c++20
LDFLAGS =
CPP_FILES := $(wildcard *.cpp)
OBJ_FILES := $(CPP_FILES:.cpp=.o)
OUTPUT_NAME = mingw-deploy

%.o: %.cpp 
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(OUTPUT_NAME): $(OBJ_FILES)
	$(CXX) $(LDFLAGS) $^ -o $@

all: $(OUTPUT_NAME)

install: all
	cp $(OUTPUT_NAME) /usr/local/bin

clean:
	rm -f $(OUTPUT_NAME).exe $(OBJ_FILES)

.PHONY: all install clean
