package DDGC::Web::Controller::InstantAnswer;
# ABSTRACT: Instant Answer Pages
use Data::Dumper;
use Moose;
use namespace::autoclean;
use Try::Tiny;

my $INST = DDGC::Config->new->appdir_path."/root/static/js";

BEGIN {extends 'Catalyst::Controller'; }

sub base :Chained('/base') :PathPart('ia') :CaptureArgs(0) {
    my ( $self, $c ) = @_;
}

sub index :Chained('base') :PathPart('') :Args(0) {
    my ( $self, $c ) = @_;
    # Retrieve / stash all IAs for index page here?

    # my @x = $c->d->rs('InstantAnswer')->all();
    # $c->stash->{ialist} = \@x;
    $c->stash->{ia_page} = "IAIndex";
    $c->stash->{ia_version} = $c->d->ia_page_version;

    $c->add_bc('Instant Answers', $c->chained_uri('InstantAnswer','index'));

    # @{$c->stash->{ialist}} = $c->d->rs('InstantAnswer')->all();
}

sub ialist_json :Chained('base') :PathPart('json') :Args(0) {
    my ( $self, $c ) = @_;

    my @x = $c->d->rs('InstantAnswer')->all();
    my @ial;

    use JSON;

    for (@x) {
        my $topics = $_->topic;
        my $attribution = $_->attribution;
        push (@ial, {
                name => $_->name,
                id => $_->id,
                example_query => $_->example_query,
                repo => $_->repo,
                src_name => $_->src_name,
                dev_milestone => $_->dev_milestone,
                perl_module => $_->perl_module,
                description => $_->description,
                topic => decode_json($topics),
                attribution => $attribution ? decode_json($attribution) : undef,
            });
    }

    $c->stash->{x} = \@ial;
    $c->stash->{not_last_url} = 1;
    $c->forward($c->view('JSON'));
}

sub iarepo :Chained('base') :PathPart('repo') :Args(1) {
    my ( $self, $c, $repo ) = @_;


    # $c->stash->{ia_repo} = $repo;

    my @x = $c->d->rs('InstantAnswer')->search({repo => $repo});

    my %iah;

    use JSON;

    for (@x) {
        my $topics = $_->topic;

        if ($_->example_query) {
            $iah{$_->id} = {
                    name => $_->name,
                    id => $_->id,
                    example_query => $_->example_query,
                    repo => $_->repo,
                    perl_module => $_->perl_module
            };
        }
    }

    $c->stash->{x} = \%iah;
    $c->stash->{not_last_url} = 1;
    $c->forward($c->view('JSON'));
}

sub queries :Chained('base') :PathPart('queries') :Args(0) {

    # my @x = $c->d->rs('InstantAnswer')->all();

}

sub ia_base :Chained('base') :PathPart('view') :CaptureArgs(1) {  # /ia/view/calculator
    my ( $self, $c, $answer_id ) = @_;

    $c->stash->{ia_page} = "IAPage";
    $c->stash->{ia_version} = $c->d->ia_page_version;
    $c->stash->{ia} = $c->d->rs('InstantAnswer')->find($answer_id);
    @{$c->stash->{issues}} = $c->d->rs('InstantAnswer::Issues')->search({instant_answer_id => $answer_id});

    use JSON;
    my $topics = $c->stash->{ia}->topic;
    $c->stash->{ia_topics} = $topics ? decode_json($topics) : undef;

    my $code = $c->stash->{ia}->code;
    $c->stash->{ia_code} = $code ? decode_json($code) : undef;

    my $other_queries = $c->stash->{ia}->other_queries;
    if ($other_queries) {
        $c->stash->{ia_other_queries} = decode_json($other_queries);
    }

    my $ia_attribution = $c->stash->{ia}->attribution;
    if($ia_attribution){
        $c->stash->{ia_attribution} = $ia_attribution ? decode_json($ia_attribution) : undef;
    }

    unless ($c->stash->{ia}) {
        $c->response->redirect($c->chained_uri('InstantAnswer','index',{ instant_answer_not_found => 1 }));
        return $c->detach;
    }

    use DDP;
    $c->stash->{ia_version} = $c->d->ia_page_version;
    $c->stash->{ia_pretty} = p $c->stash->{ia};

    my $permissions;
    my $class = "hide";

    if ($c->user) {
        $permissions = $c->stash->{ia}->users->find($c->user->id);
    }

    if ($permissions) {
        $class = "";
    }

    $c->stash->{class} = $class;

    $c->add_bc('Instant Answers', $c->chained_uri('InstantAnswer','index'));
    $c->add_bc($c->stash->{ia}->name);
}

sub ia_json :Chained('ia_base') :PathPart('json') :Args(0) {
    my ( $self, $c) = @_;

    my $ia = $c->stash->{ia};

    $c->stash->{x} =  {
                id => $ia->id,
                name => $ia->name,
                description => $ia->description,
                tab => $ia->tab,
                status => $ia->status,
                repo => $ia->repo,
                dev_milestone => $ia->dev_milestone,
                perl_module => $ia->perl_module,
                example_query => $ia->example_query,
                other_queries => $c->stash->{ia_other_queries},
                code => $c->stash->{ia_code},
                topic => $c->stash->{ia_topics},
                attribution => $c->stash->{'ia_attribution'}
    };

    # not ready yet
    # my @issues = @{$c->stash->{issues}};
    # $c->stash->{x}->{issues} = \@issues if (@issues);

    $c->stash->{not_last_url} = 1;
    $c->forward($c->view('JSON'));
}

sub ia  :Chained('ia_base') :PathPart('') :Args(0) {
    my ( $self, $c ) = @_;
}

sub save_edit :Chained('base') :PathPart('save') :Args(0) {
    my ( $self, $c ) = @_;

    my $ia = $c->d->rs('InstantAnswer')->find($c->req->params->{id});
    my $permissions;
    my $result = '';

    if ($c->user) {
       $permissions = $ia->users->find($c->user->id);
    }

    if ($permissions) {
        try {
            $ia->update({
                        $c->req->params->{field} => $c->req->params->{value}
                     });
            $result = {$c->req->params->{field} => $c->req->params->{value}};
        }
        catch {
            $c->d->errorlog("Error updating the database");
        };
    }
    
    $c->stash->{x} = {
        result => $result,
    };
   
    $c->stash->{not_last_url} = 1; 
    return $c->forward($c->view('JSON'));
}

no Moose;
__PACKAGE__->meta->make_immutable;

