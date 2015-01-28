(ns image-build.core-test
  (:require [clojure.test :refer :all]
            [image-build.core :refer :all]))

(deftest file-matchers-test
  (testing "has-pip-requirements? matches listings with a requirements.txt"
    (is (not (nil? (has-pip-requirements? ["./foo/requirements.txt" "build-requirements.txt" "foo"]))))
    (is (nil? (has-pip-requirements? ["./build-requirements.txt" "foo" "bar" "baz"]))))
  (testing "has-gemfile? matches listings with a Gemfile"
    (is (not (nil? (has-gemfile? ["./foo/Gemfile" "Gemfile.sample" "foo"]))))
    (is (nil? (has-gemfile? ["./Gemfile.sample" "foo" "bar" "baz"]))))
  (testing "has-packages-json? matches listings with a packages.json"
    (is (not (nil? (has-packages-json? ["./foo/packages.json" "packages.json.sample" "foo"]))))
    (is (nil? (has-packages-json? ["./packages.json.sample" "foo" "bar" "baz"])))))

(deftest has-package-list-test
  (testing "matches when any of a requirements.txt, Gemfile, or packages.json exists"
    (is (true? (boolean (has-package-list? ["./foo/packages.json" "bar" "baz" "chicken"]))))
    (is (true? (boolean (has-package-list? ["./foo/requirements.txt" "bar" "baz" "chicken"]))))
    (is (true? (boolean (has-package-list? ["./foo/Gemfile" "bar" "baz" "chicken"]))))
    (is (true? (boolean (has-package-list? ["./foo/packages.json" "Gemfile" "bar" "baz" "chicken"]))))))

(deftest should-use-package-lists-test
  (testing "we should use package lists whenever there are package lists but neither a default.pp or default.json"
    (is (true? (boolean (should-we-use-package-lists? ["packages.json"]))))
    (is (true? (boolean (should-we-use-package-lists? ["requirements.txt"]))))
    (is (false? (boolean (should-we-use-package-lists? ["requirements.txt" "default.pp"]))))
    (is (false? (boolean (should-we-use-package-lists? ["packages.json" "default.json"]))))
    (is (false? (boolean (should-we-use-package-lists? ["Gemfile" "default.json"]))))))
