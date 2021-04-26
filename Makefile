include venv.mk


run: venv
	venv/bin/flask run

test: venv
	venv/bin/pytest tests/

lint: venv-lint

clean: venv-clean
