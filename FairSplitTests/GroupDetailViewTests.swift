import Testing
@testable import FairSplit

struct GroupDetailViewTests {
    @Test
    func init_usesProvidedGroup() {
        let group = Group(name: "G", defaultCurrency: "USD")
        let view = GroupDetailView(group: group)
        #expect(view.group === group)
    }
}
