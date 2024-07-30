resource "aws_vpc_peering_connection" "peer" {
  vpc_id        = var.vpc_id
  peer_vpc_id   = var.peer_vpc_id
  auto_accept   = true

  tags = merge(
    {
      Name = var.peer_name
    },
    var.environment_tags
  )
}

resource "aws_route" "dev_to_admin" {
  route_table_id            = var.route_table_id
  destination_cidr_block    = var.peer_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

resource "aws_route" "admin_to_dev" {
  route_table_id            = var.admin_route_table_id
  destination_cidr_block    = var.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}