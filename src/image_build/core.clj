(ns image-build.core)

(defn zippy-files []
  (map #(.getAbsolutePath %)
       (file-seq (clojure.java.io/file "/Users/ezekiel/code/zippy"))))

(defn has-file-named? [name files]
  ; the alternating group at the beginning of this regex is so we only match at the beginning of a
  ; file name, which is either at the beginning of a new path component, or at a line beginning.
  (some #(re-matches (re-pattern (str "^(.*/|)" name "$")) %) files))

(defn has-pip-requirements? [files]
  (has-file-named? "requirements.txt" files))

; do we want to only use the lock file? maybe best to do so?
(defn has-gemfile? [files]
  (has-file-named? "Gemfile" files))

(defn has-packages-json? [files]
  (has-file-named? "packages.json" files))

(defn has-default-json? [files]
  (has-file-named? "default.json" files))

(defn has-default-pp? [files]
  (has-file-named? "default.pp" files))

(defn has-package-list? [files]
  (map #(or (has-packages-json? %)
            (has-pip-requirements? %)
            (has-gemfile? %))
       files))

(defn should-we-use-package-lists? [files]
  (and (not (or (has-default-pp? files)
                (has-default-json? files)))
       (has-package-list? files)))

(defn should-we-use-puppet? [files]
  (and (has-default-pp? files)
       (not (has-default-json? files))))

(defn should-we-use-packer? [files]
  (and (has-default-json? file)))

(defn foo
  "I don't do a whole lot."
  [x]
  (println x "Hello, World!"))
