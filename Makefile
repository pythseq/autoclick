tests = tests
module = autoclick
version = 0.5.0
#pytestops = "--full-trace"
#pytestops = "-v -s"
repo = jdidion/$(module)
desc = Release $(version)

BUILD = poetry build && pip install --upgrade dist/$(module)-$(version)-py3-none-any.whl $(installargs)
TEST  = pytest -s -vv --show-capture=all --cov --cov-report term-missing $(pytestopts) $(tests)

all:
	$(BUILD)
	$(TEST)

install:
	$(BUILD)

test:
	$(TEST)

docs:
	make -C docs api
	make -C docs html

lint:
	pylint $(module)

clean:
	rm -Rf __pycache__
	rm -Rf **/__pycache__/*
	rm -Rf **/*.c
	rm -Rf **/*.so
	rm -Rf **/*.pyc
	rm -Rf dist
	rm -Rf build
	rm -Rf $(module).egg-info

docker:
	# build
	docker build -f Dockerfile -t $(repo):$(version) .
	# add alternate tags
	docker tag $(repo):$(version) $(repo):latest
	# push to Docker Hub
	docker login -u jdidion && \
	docker push $(repo)

release:
	$(clean)
	# tag
	git tag $(version)
	# build
	$(BUILD)
	$(TEST)
	# release
	poetry publish
	git push origin --tags
	$(github_release)
	# $(docker)

github_release:
	curl -v -i -X POST \
		-H "Content-Type:application/json" \
		-H "Authorization: token $(token)" \
		https://api.github.com/repos/$(repo)/releases \
		-d '{"tag_name":"$(version)","target_commitish": "master","name": "$(version)","body": "$(desc)","draft": false,"prerelease": false}'
