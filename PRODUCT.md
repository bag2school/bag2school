# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users

The primary users are parents or guardians with children currently below Grade 4 of elementary school who need to monitor school routines. The initial target is parents. Supporting families with older children may be considered later; it is not a current requirement.

## Product Purpose

Bag2School helps parents coordinate a child's school schedule, preparation needs, and homework in one app. Success means a parent can understand what is planned and what needs attention or preparation for the child.

## Positioning

Bag2School brings a child-centered schedule, preparation checklist, homework workflow, and family access roles together in one school-planning app. Bagi is the friendly companion within those workflows.

## Operating Context

The current release target is Android phones. Parents use child profiles to monitor school activities and tasks. The project currently connects to a local Supabase development environment for testing; migration to a hosted cloud environment is planned for a later stage when the app is ready.

## Capabilities and Constraints

- The app includes child profiles, family membership and role-based access.
- School schedules include recurring activities and school-related events such as exams.
- Preparation tasks can be associated with scheduled activities and tracked as ready.
- Homework can be recorded and tracked separately.
- The notification bell provides an in-app family activity inbox. Device-level scheduled reminders and system notifications are not implemented yet.
- Preserve existing authentication, authorization, Supabase integration, data models, navigation, and working user flows during visual work.
- English is the current interface language. Indonesian localization is a future possibility.
- The current development database is local; do not describe the app as hosted or production-cloud ready.

## Brand Commitments

- Keep the Bag2School name and Bagi mascot.
- Preserve the existing app design and cream-and-orange identity; UI refinement should not become a redesign.
- Bagi's dialogue should feel warm, friendly, and supportive.

## Evidence on Hand

- Flutter/Dart application source, including schedule, preparation, homework, child profile, family, and settings flows.
- Existing app screenshots in `flutter_*.png` and Bagi character assets under `assets/bagi/`.
- The existing project and Supabase development configuration are implementation evidence only; do not treat the local environment as a production deployment.

## Product Principles

- Help parents monitor the child's school day and readiness in one place.
- Keep activities and tasks associated with the relevant child.
- Make family permissions clear while keeping parents as the current primary audience.
- Use Bagi to make guidance reassuring and approachable.
- Keep local testing separate from the future cloud release stage.