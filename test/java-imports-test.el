;;; groovy-imports-test.el --- tests for groovy imports

;; Copyright (C) 2016 Miro Bezjak (original code by Matthew Lee Hinman)

;;; Code:

(require 'ert)
(load-file "groovy-imports.el")


(ert-deftest t-import-for-line ()
  (with-temp-buffer
    (insert "import java.util.List")
    (should (equal (groovy-imports-import-for-line)
                   "java.util.List")))
  ;; semicolons are optional in groovy but can be there
  (with-temp-buffer
    (insert "import java.util.List;")
    (should (equal (groovy-imports-import-for-line)
                   "java.util.List")))
  (with-temp-buffer
    (insert "     import org.writequit.Thingy  ")
    (should (equal (groovy-imports-import-for-line)
                   "org.writequit.Thingy"))))


(ert-deftest t-go-to-imports-start ()
  ;; both package and imports present? Goto to the first import line beginning
  (with-temp-buffer
    (insert "package mypackage\n")
    (insert "\n")
    (insert "import java.util.List\n")
    (insert "import java.util.ArrayList\n")
    (insert "\n\n")
    (groovy-imports-go-to-imports-start)
    (should (equal (line-number-at-pos) 3)))

  ;; no package and imports present? First import line
  (with-temp-buffer
    (insert "\n")
    (insert "\n")
    (insert "\n")
    (insert "import java.util.List\n")
    (insert "import java.util.ArrayList\n")
    (insert "\n\n")
    (groovy-imports-go-to-imports-start)
    (should (equal (line-number-at-pos) 4)))

  ;; package present, no imports? Add a correct import place, keeping the empty
  ;; lines
  (with-temp-buffer
    (insert "\n")
    (insert "package mypackage\n")
    (insert "\n")
    (insert "\n")
    (insert "class A {}\n")
    (groovy-imports-go-to-imports-start)
    (should (equal (line-number-at-pos) 4))
    (should (equal (count-lines (point-min) (point-max)) 7)))

  ;; no package, no imports? Stay in the beginning, add lines required
  (with-temp-buffer
    (insert "\n")
    (insert "\n")
    (insert "\n")
    (insert "class A {}\n")
    (groovy-imports-go-to-imports-start)
    (should (equal (line-number-at-pos) 1))
    (should (equal (count-lines (point-min) (point-max)) 5))))

(ert-deftest t-add-imports ()
  (with-temp-buffer
    (setq-local groovy-imports-find-block-function
                #'groovy-imports-find-place-after-last-import)
    (insert "package mypackage\n\n")
    (insert "import java.util.List\n\n\n")
    (groovy-imports-add-import-with-package "ArrayList" "java.util")
    (should
     (equal
      (buffer-string)
      (concat
       "package mypackage\n\n"
       "import java.util.List\n"
       "import java.util.ArrayList\n\n\n"))))

  ;; Test for annotation importing
  (with-temp-buffer
    (insert "package mypackage\n\n")
    (insert "import java.util.List\n\n\n")
    (groovy-imports-add-import-with-package "@MyAnnotation" "org.foo")
    (should
     (equal
      (buffer-string)
      (concat
       "package mypackage\n\n"
       "import java.util.List\n"
       "import org.foo.MyAnnotation\n\n\n"))))

  (with-temp-buffer
    (setq-local groovy-imports-find-block-function
                #'groovy-imports-find-place-sorted-block)
    (insert "package mypackage\n\n")
    (insert "import java.util.List\n\n\n")
    (groovy-imports-add-import-with-package "ArrayList" "java.util")
    (should
     (equal
      (buffer-string)
      (concat
       "package mypackage\n\n"
       "import java.util.ArrayList\n"
       "import java.util.List\n\n\n")))))

(ert-deftest t-list-imports ()
  (with-temp-buffer
    (insert "package mypackage\n")
    (insert "\n")
    (insert "import org.Thing\n")
    (insert "\n")
    (insert "import java.util.List\n")
    (insert "import java.util.ArrayList\n")
    (insert "\n")
    (insert "public class Foo {}")
    (should
     (equal
      (groovy-imports-list-imports)
      '("org.Thing" "java.util.List" "java.util.ArrayList")))))

(ert-deftest t-pkg-and-class-from-import ()
  (should
   (equal (groovy-imports-get-package-and-class "java.util.Map")
          '("java.util" "Map")))
  (should
   (equal (groovy-imports-get-package-and-class "org.foo.bar.baz.ThingOne")
          '("org.foo.bar.baz" "ThingOne")))
  (should
   (equal (groovy-imports-get-package-and-class "somePackage.*") nil)))

;; End:
;;; groovy-imports-test.el ends here
