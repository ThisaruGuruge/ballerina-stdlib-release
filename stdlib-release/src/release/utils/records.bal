public type Module record {|
    string name;
    string 'version;
    string branch;
    int level;
    boolean release;
    string notes;
    boolean releaseStarted = false;
|};
