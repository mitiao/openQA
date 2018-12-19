# Copyright (C) 2018 SUSE LLC
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, see <http://www.gnu.org/licenses/>.

package OpenQA::WebAPI::Command::gru::run;
use Mojo::Base 'Mojolicious::Command';

use Mojo::Util 'getopt';
use OpenQA::WebAPI::GruJob;

has description => 'Start Gru worker';
has usage       => sub { shift->extract_usage };

sub run {
    my ($self, @args) = @_;

    getopt \@args, 'o|oneshot' => \(my $oneshot);

    my $minion = $self->app->minion;
    $minion->on(
        worker => sub {
            my ($minion, $worker) = @_;

            # Only one job can run at a time for now (until all Gru tasks are parallelism safe)
            $worker->status->{jobs} = 1;

            $worker->on(
                dequeue => sub {
                    my ($worker, $job) = @_;

                    # Reblessing the job is fine for now, but in the future it would be nice
                    # to use a role instead
                    bless $job, 'OpenQA::WebAPI::GruJob';
                });
        });

    if   ($oneshot) { $minion->perform_jobs }
    else            { $minion->worker->run }
}

1;

=encoding utf8

=head1 NAME

OpenQA::WebAPI::Command::gru::run - Gru run command

=head1 SYNOPSIS

  Usage: APPLICATION gru run [OPTIONS]

    script/openqa gru run

  Options:
    -o, --oneshot   Perform all currently enqueued jobs and then exit

=head1 DESCRIPTION

L<OpenQA::WebAPI::Command::gru::run> is a wrapper around L<Minion::Worker> that
runs a L<Minion> worker with some Gru extensions.

=cut
