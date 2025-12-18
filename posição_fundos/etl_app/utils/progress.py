"""
Barra de progresso e feedback visual usando Rich
"""

from rich.progress import (
    Progress,
    SpinnerColumn,
    BarColumn,
    TextColumn,
    TimeRemainingColumn,
    TaskProgressColumn
)
from rich.console import Console
from rich.table import Table
from typing import Optional, Iterator, Any

console = Console()

class ProgressTracker:
    """Gerenciador de progresso visual"""

    def __init__(self):
        self.progress = Progress(
            SpinnerColumn(),
            TextColumn("[bold blue]{task.description}"),
            BarColumn(),
            TaskProgressColumn(),
            TimeRemainingColumn(),
            console=console
        )

    def __enter__(self):
        self.progress.__enter__()
        return self

    def __exit__(self, *args):
        self.progress.__exit__(*args)

    def add_task(self, description: str, total: Optional[int] = None):
        """Adiciona uma nova task"""
        return self.progress.add_task(description, total=total)

    def update(self, task_id, **kwargs):
        """Atualiza progresso de uma task"""
        self.progress.update(task_id, **kwargs)

    def advance(self, task_id, advance: float = 1):
        """Avança o progresso"""
        self.progress.advance(task_id, advance)

def track_progress(items: list, description: str) -> Iterator[Any]:
    """
    Context manager para iterar com progresso

    Args:
        items: Lista de itens para processar
        description: Descrição da tarefa

    Yields:
        Cada item da lista

    Example:
        for arquivo in track_progress(arquivos, "Processando arquivos"):
            processar(arquivo)
    """
    with ProgressTracker() as progress:
        task = progress.add_task(description, total=len(items))

        for item in items:
            yield item
            progress.advance(task)

def print_summary_table(title: str, data: dict):
    """
    Imprime tabela de resumo colorida

    Args:
        title: Título da tabela
        data: Dicionário {chave: valor}

    Example:
        print_summary_table("Resumo", {"Fundos": 289, "Posições": 6342})
    """
    table = Table(title=title, show_header=True, header_style="bold magenta")

    table.add_column("Métrica", style="cyan", no_wrap=True)
    table.add_column("Valor", style="green")

    for key, value in data.items():
        if isinstance(value, (int, float)):
            formatted_value = f"{value:,}".replace(',', '.')
        else:
            formatted_value = str(value)

        table.add_row(key, formatted_value)

    console.print(table)

def print_success(message: str):
    """Imprime mensagem de sucesso"""
    console.print(f"[bold green]✓[/bold green] {message}")

def print_error(message: str):
    """Imprime mensagem de erro"""
    console.print(f"[bold red]✗[/bold red] {message}")

def print_warning(message: str):
    """Imprime mensagem de aviso"""
    console.print(f"[bold yellow]⚠[/bold yellow] {message}")

def print_info(message: str):
    """Imprime mensagem informativa"""
    console.print(f"[bold blue]ℹ[/bold blue] {message}")

if __name__ == '__main__':
    # Teste de progresso
    import time

    print_info("Testando sistema de progresso...")

    items = range(100)
    for i in track_progress(list(items), "Processando items"):
        time.sleep(0.02)  # Simula processamento

    print_success("Teste concluído!")

    # Teste de tabela
    print_summary_table("Resumo de Teste", {
        "Total de Items": 100,
        "Sucesso": 95,
        "Erros": 5,
        "Taxa": "95%"
    })
