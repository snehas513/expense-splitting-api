
require "rails_helper"

RSpec.describe Groups::InviteableUsersService do
  describe "#call" do
    let(:admin) { create(:user, status: "active") }
    let(:group) { create(:group) }
    let!(:admin_membership) do
      create(:membership, user: admin, group: group, role: "admin", status: "active")
    end

    let(:result) do
      described_class.new(user: admin, group: group).call
    end

    context "when valid" do
      let!(:eligible_user) { create(:user, status: "active") }

      it "returns active users who are not members or pending invitees" do

        expect(result[:success]).to be(true)
        expect(result[:users]).to include(
          hash_including(
            id: eligible_user.id,
            name: eligible_user.name,
            email: eligible_user.email
          )
        )
      end

      it "excludes the current user" do
        user_ids = result[:users].pluck(:id)

        expect(user_ids).not_to include(admin.id)
      end

      it "excludes inactive users" do
        inactive_user = create(:user, status: "deactivated")

        user_ids = result[:users].pluck(:id)

        expect(user_ids).not_to include(inactive_user.id)
      end

      it "excludes existing active group members" do
        member = create(:user, status: "active")
        create(:membership, user: member, group: group, status: "active")

        user_ids = result[:users].pluck(:id)

        expect(user_ids).not_to include(member.id)
      end

      it "excludes users with pending invitations" do
        invited_user = create(:user, status: "active")

        create(
          :invitation,
          group: group,
          invited_user: invited_user,
          invited_by: admin,
          status: "pending"
        )

        user_ids = result[:users].pluck(:id)

        expect(user_ids).not_to include(invited_user.id)
      end

      it "returns only the first 20 users" do
        create_list(:user, 21, status: "active")

        expect(result[:users].size).to eq(20)
      end

      context "when query is provided" do
        let!(:matching_user) do
          create(:user, name: "Venus", email: "venus@example.com")
        end

        let!(:other_user) do
          create(:user, name: "Alex", email: "alex@example.com")
        end

        it "filters users by name" do
          result = described_class.new(
            user: admin,
            group: group,
            query: "Venus"
          ).call

          expect(result[:users].pluck(:id)).to include(matching_user.id)
          expect(result[:users].pluck(:id)).not_to include(other_user.id)
        end

        it "filters users by email" do
          result = described_class.new(
            user: admin,
            group: group,
            query: "venus@example.com"
          ).call

          expect(result[:users].pluck(:id)).to include(matching_user.id)
          expect(result[:users].pluck(:id)).not_to include(other_user.id)
        end
      end
    end

    context "when user is missing" do
      let(:result) do
        described_class.new(user: nil, group: group).call
      end

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("User is required")
      end
    end

    context "when user is inactive" do
      let(:admin) { create(:user, status: "deactivated") }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("User must have an active account")
      end
    end

    context "when group is missing" do
      let(:group) { nil }
      let(:admin_membership) { [] }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include("Group is required")
      end
    end

    context "when user is not an active admin member" do
      let(:admin_membership) { nil }

      it "returns an error" do
        expect(result[:success]).to be(false)
        expect(result[:errors]).to include(
          "User is not an active admin member of the group"
        )
      end
    end
  end
end
