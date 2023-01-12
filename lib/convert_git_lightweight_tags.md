# Types of git tags and howto inspect them
Git repos may contain two types of tags, annotated tags and lightweight tags.

Lightweight tags are references which point directly to other non-tag git objects. Often lightweight tags point to commits, but you may also tag the other git objects trees and blobs. You can inspect all those references locally in .git/refs/tags/... or in .git/packed_refs. E.g. If <x> is the GUID of commit, then a file ./git/refs/tags/a containing <x> defines a lightweight tag pointing to commit <x>. Be aware that lightweight tags store no metadata about the tag besides it's name. You can't store who created the tag, when the tag was created, add a signature or a descriptive text for the tag.

An Annotated tag is technically a lightweight tag which point to a git tag object. And this tag object stores the guid of the object this tag should point to alongside with metadata like: who created the tag, when was it created, ... 

The following example creates a repo with a commit, creates a lightweight and an annotated tag and shows how they are persisted.

```
> git init testRepo
...
> cd testRepo/
> touch a; git add a; git commit -m 'created file a'
[master (root-commit) 70e8683] created file a
 1 file changed, 0 insertions(+), 0 deletions(-)
 create mode 100644 a
> git log --oneline
70e8683 (HEAD -> master) created file a
> git tag lwTag     # create a lightweight tag
> git tag -a -m 'description for annotated tag' aTag    # create an annotated tag
> git log --oneline    # see the additional references listed for the commit
70e8683 (HEAD -> master, tag: lwTag, tag: aTag) created file a
> grep ^ .git/refs/tags/*   # print the content of all files in .git/refs/tags/*
.git/refs/tags/aTag:37fde2ae670703b26bc70d9f02944fb8339c6967
.git/refs/tags/lwTag:70e86834427b6abf4f7e5dde19b8561e30ee79a1
> # we know that 70e8683 is a commit, but where does 37fde2a point to?
> git show 37fde2a    # this id points to a tag object, which itself points to a commit object
tag aTag
Tagger: Christian Halstrick <christian.halstrick@sap.com>
Date:   Thu Jan 12 17:42:43 2023 +0100

description for annotated tag

commit 70e86834427b6abf4f7e5dde19b8561e30ee79a1 (HEAD -> master, tag: lwTag, tag: aTag)
Author: Christian Halstrick <christian.halstrick@sap.com>
Date:   Thu Jan 12 17:41:29 2023 +0100

    created file a

diff --git a/a b/a
new file mode 100644
index 0000000..e69de29
> git for-each-ref refs/tags
37fde2ae670703b26bc70d9f02944fb8339c6967 tag    refs/tags/aTag
70e86834427b6abf4f7e5dde19b8561e30ee79a1 commit refs/tags/lwTag
```

To list all lightweight tags you may use the git-for-each-ref command and grep for lines without the word 'tag'. Make sure to search for complete words `tag` because also for lightweight tags the substring `tag` is included in `...refs/tags/...` 
```
> git for-each-ref refs/tags
37fde2ae670703b26bc70d9f02944fb8339c6967 tag    refs/tags/aTag
70e86834427b6abf4f7e5dde19b8561e30ee79a1 commit refs/tags/lwTag
> git for-each-ref refs/tags | grep -vw tag
37fde2ae670703b26bc70d9f02944fb8339c6967 tag    refs/tags/aTag
>
```

# Convert lightweight tags to annotated tags in a local git repo
Since we found a way to find lightweight tags we can create annotated tags to point to the same objects. Take care to skip annotated tags and to guess a good creation date for the new tags

```
git for-each-ref refs/tags | while read id type ref ;do if [ $type != "tag" ] ;then d="$(date)"; [ $type == "commit" ] && d="$(git show $id --format=%aD | head -1 )"; GIT_COMMITTER_DATE="$d" git tag -a -f -m' ' ${ref#refs/tags/} $id; fi; done
```

# Push annotated tags to a remote repo
