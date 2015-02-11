(ns image-build.core
  (:require [me.raynes.conch.low-level :as sh]))

(defn project-files [path]
    (map #(.getAbsolutePath %)
         (file-seq (clojure.java.io/file path))))

(defn project-from-directory [path]
  {:files (project-files path)
    :path path})

(defn has-file-named? [name project]
  (let [files (:files project)
        path  (:path project)]
    ; the alternating group at the beginning of this regex is so we only match at the beginning of a
    ; file name, which is either at the beginning of a new path component, or at a line beginning.
    (some #(re-matches (re-pattern (str "^" path "/" name "$")) %) files)))

(defn has-pip-requirements? [project]
  (has-file-named? "requirements.txt" project))

; do we want to only use the lock file? maybe best to do so?
(defn has-gemfile? [project]
  (has-file-named? "Gemfile" project))

(defn has-packages-json? [project]
  (has-file-named? "packages.json" project))

(defn has-default-json? [project]
  (has-file-named? "default.json" project))

(defn has-default-pp? [project]
  (has-file-named? "default.pp" project))

(defn has-package-list? [project]
  (map #(or (has-packages-json? %)
            (has-pip-requirements? %)
            (has-gemfile? %))
       (:files project)))

(defn should-we-use-package-lists? [project]
  (and (not (or (has-default-pp? project)
                (has-default-json? project)))
       (has-package-list? project)))

(defn should-we-use-puppet? [project]
  (and (has-default-pp? project)
       (not (has-default-json? project))))

(defn should-we-use-packer? [project]
  (and (has-default-json? project)))

(defn resource [path]
  (when path
    (-> (Thread/currentThread) .getContextClassLoader (.getResource path))))

(defn slurp-n-spit [in out]
  (spit out
        (slurp (clojure.java.io/file (clojure.java.io/resource in)))
        :append false))

(defn put-puppet-file-in-place [project]
  (let [puppetfile-path (str (:path project) "/Puppetfile")
        puppet-path (str (:path project) "/default.pp")]
    (println puppetfile-path)
    (println puppet-path)
    (slurp-n-spit "Puppetfile" puppetfile-path)
    (slurp-n-spit "ruby.pp" puppet-path)))

(defn put-packer-file-in-place [project]
  (slurp-n-spit "default.json" (str (:path project) "/default.json")))

(defn run-packer [project]
  ; maybe we want to pop to a sub process for this, or always reset the cwd later?
  (let [results (sh/proc (-> "packer_build" resource .getPath) :dir (:path project))]
    (clojure.java.io/copy (:out results) *out* :redirect-err true :buffer-size 1)))

; NOTE: builders should always ensure their own isolation from the environment. this means
; filesystem, environment variables, installed packages, etcetera.

(defn packer-builder [project]
  (println "using packer builder")
  (run-packer project))

(defn puppet-builder [project]
  (println "using puppet builder")
  (put-packer-file-in-place project)
  (packer-builder project))

(defn package-lists-builder [project]
  (println "using package-lists builder")
  (put-puppet-file-in-place project)
  (puppet-builder project))

(defn what-should-we-use? [project]
  (cond (should-we-use-packer? project) packer-builder
        (should-we-use-puppet? project) puppet-builder
        (should-we-use-package-lists? project) package-lists-builder
        true (fn [ignored] println "no builder matched")))

(defn build-it! [project]
  (let [builder (what-should-we-use? project)]
    (builder project)))

(defn -main
  "checks the filesystem for which thing we should use"
  [& [given-path]]
  (let [path (or given-path "/Users/ezekiel/code/zippy")]
    (build-it! (project-from-directory path))
    (await)))
