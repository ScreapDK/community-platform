#!/usr/bin/env perl

# Github contributor stats, in this repo because why not?

use strict;
use warnings;
use IPC::Open3;
use File::Temp qw/ tempfile tempdir /;
use Term::ReadKey;
use Net::GitHub;
use Time::Piece;
use Time::Seconds;
use Try::Tiny;
use Set::Scalar;
use Data::Dumper;

$|=1;

my $repository_url = 'https://github.com/duckduckgo/';

my $core_team_github = {
    bsstoner    =>  {
        name =>  'Brian Stoner'
    },
    b1ake       =>  {
        name =>  'Blake Jennelle'
    },
    davidmascio =>  {
    },
    chrismorast => {
    },
    faraday     =>  {
        name =>  'Çağatay Çallı'
    },
    friedo      =>  {
        name =>  'Mike Friedman'
    },
    getty       =>  {
        name =>  'Torsten Raudssus'
    },
    hunterlang  =>  {
        name =>  'Hunter Lang'
    },
    jagtalon    =>  {
        name =>  'Jag Talon'
    },
    jbarrett    =>  {
        name =>  'John Barrett'
    },
    jkanarek    =>  {
    },
    kevinpelgrims => {
        name =>  'Kevin Pelgrims'
    },
    koenmetsu   =>  {
        name =>  'Koen Metsu'
    },
    malbin      =>  {
        name =>  'Jaryd Malbin'
    },
    moollaza    =>  {
        name =>  'Zaahir Moolla'
    },
    mrshu       =>  {
        name =>  'Marek Šuppa'
    },
    nilnilnil   =>  {
        name =>  'Caine Tighe'
    },
    pswam       =>  {
        name =>  'Prakash S'
    },
    russellholt =>  {
        name =>  'Russell Holt'
    },
    sdougbrown  =>  {
        name =>  'Doug Brown'
    },
    yegg        =>  {
        name =>  'Gabriel Weinberg'
    },
    zekiel      =>  {
        name =>  'Zac Pappis'
    },
    ddh5        => {
        name =>  'DuckDuckHack Five',
    },
    dax => {
        name => 'Dax the Duck',
    },
    ddg => {
        name => 'DuckDuckGo',
    },
    abeyang     =>  {
        name =>  'Abe Yang',
    },
    jdorweiler  =>  {
        name =>  'Jason',
    },
    thm => {
        name =>  'Thom',
    },
    tommytommytommy => {
        name => 'Tommy Leung',
    },
    'AdamSC1-ddg' => {
    },
    'andrey-p' => {
        name => 'Andrey Pissantchev',
    },
    MariagraziaAlastra => {
        name => 'Maria Grazia Alastra',
    },
    zachthompson => {
        name => 'Zach Thompson',
    },
    tagawa => {
        name => 'Daniel Davis',
    },
};

# Should come from API in future:
my @projects = qw/
    zeroclickinfo-goodies
    zeroclickinfo-spice
    zeroclickinfo-longtail
    zeroclickinfo-fathead
    zeroclickinfo-goodie-spell
    zeroclickinfo-goodie-math
    zeroclickinfo-goodie-isvalid
    zeroclickinfo-goodie-chords
    zeroclickinfo-goodie-qrcode
/;

sub github_creds {
    ($ENV{DDGC_GITHUB_TOKEN}) && return ( access_token => $ENV{DDGC_GITHUB_TOKEN} );

    print "GitHub API limits requests to 60 per hour, please provide login so this script doesn't fail\n\n";

    print "Username : ";
    chomp (my $u = <STDIN>);

    ReadMode('noecho');
    print "Password : ";
    chomp (my $p = <STDIN>);
    ReadMode(0); print "\n";

    return ( login => $u, pass => $p );
}

my $gh = Net::GitHub->new( github_creds() );
my $today = localtime;
my $periods = [
    { start => $today - (ONE_DAY * 360), end => $today - (ONE_DAY * 270) },
    { start => $today - (ONE_DAY * 270), end => $today - (ONE_DAY * 180) },
    { start => $today - (ONE_DAY * 180), end => $today - (ONE_DAY * 90) },
    { start => $today - (ONE_DAY * 90),  end => $today },
];

my $log;
my @sets;
print "working";

for (0..$#$periods) {
    my $set = Set::Scalar->new;
    
    for my $project (@projects) {
    
        my $since = $periods->[$_]->{start}->ymd . "T00:00:00Z";
        my $until = $periods->[$_]->{end}->ymd . "T00:00:00Z";
        my @commits = $gh->repos->commits('duckduckgo', $project, { since => $since, until => $until });

            while($gh->repos->has_next_page){
                push(@commits, $gh->repos->next_page);
            }

            for my $commit (@commits) {
                #my $author = $commit->{author}->{login} || $commit->{committer}->{login} || "";
                my $author = $commit->{author}->{login} || $commit->{committer}->{login} ||
                    $commit->{commit}->{author}->{name} || $commit->{commit}->{committer}->{name} || "";

                $author or next;
                unless ( grep { $_ =~ /$author/i ||
                                ( $core_team_github->{$_}->{name} &&
                                  $core_team_github->{$_}->{name} =~ /$author/ )
                              } (keys $core_team_github) ) {
                    $log->[$_]->{authors}->{$author} = 1;
                    $set->insert($author);
                }
            }

        my @pulls = $gh->pull_request->pulls('duckduckgo', $project, { state  => 'open', sort => 'created', });

        while($gh->pull_request->has_next_page){
            push(@pulls, $gh->pull_request->next_page);
        }

        for my $pull (@pulls) {

            next unless ( $pull->{created_at} lt $until &&
                          $pull->{created_at} ge $since );

            my $author = $pull->{user}->{login}; # PRs should always have a login.
            $author or next;

            unless ( grep { $_ =~ /^$author$/i } (keys $core_team_github) ) {
                $log->[$_]->{authors}->{$author} = 1;
                $set->insert($author);
            }
        }
        print ". ";
    }
    push(@sets, $set);
}


 for (0..$#$periods) {
     printf ("cycle %d: %s through %s\n", $_+1, $periods->[$_]->{start}->mdy, ($periods->[$_]->{end} - ONE_DAY )->mdy);
 }

# 1 time period window
printf "\n\nParticipation in 2 consecutive 90-day cycles\n";
for(my $i = 0; $i < scalar @sets; $i++){
    next unless $sets[$i]->members;
    my $p2 = $i+1;
    next unless $p2 < scalar @sets;

    my $intersection_1 = $sets[$i] * $sets[$p2];

    printf ("Cycles %d and %d: %d\n", $i+1, $p2+1, $intersection_1->size);
    printf ("%s\n\n", join(', ', $intersection_1->members));
}

my $three_1 =  $sets[0] * $sets[1] * $sets[2];
my $three_2 =  $sets[1] * $sets[2] * $sets[3];


printf ("\nParticipation in 3 consecutive cycles 1-3: %d\n", $three_1->size);
printf ("%s\n", join(', ', $three_1->members));
printf ("\nParticipation in 3 consecutive cycles 2-4: %d\n", $three_2->size);
printf ("%s\n", join(', ', $three_2->members));

my $four = $sets[0] * $sets[1] * $sets[2] * $sets[3];

printf ("\nParticipation in 4 consecutive cycles 1-4: %d\n", $four->size);
printf ("%s\n\n", join(', ', $four->members));


# 2 time period window
for(my $i = 0; $i < scalar @sets; $i++){
    next unless $sets[$i]->members;
    my $p2 = $i+2;
    next unless $p2 < scalar @sets;

    my $intersection_1 = $sets[$i] * $sets[$p2];
    
    printf ("\nParticipation in cycles %d and %d: %d\n", $i+1, $p2+1,  scalar $intersection_1->size);
    printf ("%s\n\n", join(', ', $intersection_1->members));
}

# 3 time period window
for(my $i = 0; $i < scalar @sets; $i++){
    next unless $sets[$i]->members;
    my $p2 = $i+3;

    next unless $p2 < scalar @sets;

    my $intersection_1 = $sets[$i] * $sets[$p2];

    printf ("\nParticipation in cycles %d and %d: %d\n", $i+1, $p2+1,  scalar $intersection_1->size);
    printf ("%s\n\n", join(', ', $intersection_1->members));
}


 for (0..$#$periods) {
     print "\nUnique GitHub contributors " . $periods->[$_]->{start}->mdy . " through " . ($periods->[$_]->{end} - ONE_DAY )->mdy . "\t";
     print scalar (keys $log->[$_]->{authors}) . "\n";
     print "Logins : " . join(', ', sort keys $log->[$_]->{authors}) . "\n";
 }

