all: 
	rebar compile

clean:
	rebar clean
	rm -r bin
	rm -r logs
